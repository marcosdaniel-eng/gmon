import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gmon/Admin_menu.dart';
import 'package:gmon/Monitor_menu.dart';
import 'package:gmon/auth_services.dart';
import 'package:gmon/google_sign_in.dart';
import 'package:gmon/recover_password.dart';
import 'package:gmon/signup_page.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false; //tiempo de carga
  bool isCPasswordHidden = true;
  final AuthServices _authServices = AuthServices();

  void login()async{
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    setState(() {
      isLoading = true;
    });

    // Funcion de registro de usuarios
    // Se llama al metodo de authservices para el inicio de sesión de usuarios
    String? result = await _authServices
        .login(
          email: emailController.text,
          password: passwordController.text);
    setState(() {
      isLoading = false;
    });
    //Cambio de pantalla de acuerdo al rol
    if(result == "Admin"){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:(_) => const Admin_Menu(),
        ),
      );
    }
    else if(result == "Monitor"){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:(_) => const Monitor_menu(),
        ),
      );
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inicio fallido")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
            image:AssetImage('assets/fondo_login.jpg'),
            fit:BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Image.asset("assets/logo_inicio.png"),
              SizedBox(height: 20),
              //Caja de texto correo electrónico
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Correo electrónico:",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
              //Caja de texto contraseña
              SizedBox(height: 15),
              TextField(
                controller:passwordController,
                decoration: InputDecoration(
                  labelText: "Contraseña:",
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: IconButton(
                      onPressed: (){
                        setState(() {
                          isCPasswordHidden = !isCPasswordHidden;
                        });
                      },
                      icon:Icon(isCPasswordHidden ?Icons.visibility_off:Icons.visibility,)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                obscureText: isCPasswordHidden,
              ),
              //Boton de inicio de sesión
              const SizedBox(height: 20),
              isLoading ? Center(child: CircularProgressIndicator(),):
              Center(
              child:SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3C66),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Text("Iniciar sesión",style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),),
                ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children:[
                InkWell(
                  onTap:(){
                    Navigator.pushReplacement(
                      context,MaterialPageRoute(builder: (_) => const RecoverPassword()));
                  },
                  child: Text(
                    "¿Olvide mi contraseña?",
                    style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[350],
                    )
                  ),
                ),
              ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                   Text(
                        "¿Aún no tienes cuenta?",
                        style: TextStyle(fontSize: 18,
                          color: Colors.blue[350],
                        )
                    ),
                  InkWell(
                    onTap:(){
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder:(_) => const SignupPage(),
                          ),
                      );
                    },
                    child: Text(
                        "Crea una",
                        style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[350],
                        )
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              SizedBox(
                width: 280,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                  onPressed: () async{
                    final provider =
                    Provider.of<GoogleSignInProvider>(context, listen: false);

                    final role = await provider.googleLogin();

                    print("ROLE GOOGLE: $role");

                    if (!context.mounted) return;

                    if (role == 'Admin') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => Admin_Menu()),
                      );
                    } else if (role == 'Monitor') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => Monitor_menu()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("No se encontró rol del usuario")),
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/google.png", height: 20),
                      SizedBox(width: 10),
                      Text(
                        "Iniciar sesión con Google",
                        style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

