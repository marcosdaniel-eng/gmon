
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'home_page.dart';
import 'splashScreen.dart';
import 'Admin_menu.dart';
import 'Monitor_menu.dart';
import 'google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  runApp(MyApp(showHome: showHome));
}

class MyApp extends StatelessWidget {
  final bool showHome;

  const MyApp({
    super.key,
    required this.showHome,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GoogleSignInProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthGate(showHome: showHome),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  final bool showHome;

  const AuthGate({
    super.key,
    required this.showHome,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<String?> _roleFuture;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _roleFuture = _getUserRole();
  }

  Future<String?> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();

    try {
      final document = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      if (!document.exists) return null;

      final role = document.data()?['role'] as String?;

      if (role == 'Admin' || role == 'Monitor') {
        await prefs.setString('role_${user.uid}', role!);
        return role;
      }

      return null;
    } catch (_) {
      // Si no hay internet, recuperar el último rol guardado
      return prefs.getString('role_${user.uid}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingScreen();
        }

        final user = snapshot.data;

        if (user == null) {
          _currentUid = null;
          return widget.showHome
              ? const HomePage()
              : const Splashscreen();
        }

        if (_currentUid != user.uid) {
          _currentUid = user.uid;
          _roleFuture = _getUserRole();
        }

        return FutureBuilder<String?>(
          future: _roleFuture,
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState ==
                ConnectionState.waiting) {
              return _loadingScreen();
            }

            final role = roleSnapshot.data;

            if (role == 'Admin') {
              return const Admin_Menu();
            }

            if (role == 'Monitor') {
              return const Monitor_menu();
            }

            return const Scaffold(
              body: Center(
                child: Text(
                  'No fue posible verificar tu rol.\n'
                      'Conéctate a internet e intenta nuevamente.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _loadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
