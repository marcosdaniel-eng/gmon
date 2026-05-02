import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider extends ChangeNotifier{
  final googleSignIn = GoogleSignIn(
    clientId: "736572913019-pv0j7fbov2dq974q6r1lohogabl4g6fp.apps.googleusercontent.com",
  );
  GoogleSignInAccount? _user;
  GoogleSignInAccount? get user=>_user;

  Future <String?> googleLogin() async{
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCredential.user;
    if (user == null) return null;

    print("UID GOOGLE: ${user.uid}");
    print("EMAIL GOOGLE: ${user.email}");

    final docUser =
    FirebaseFirestore.instance.collection("usuarios").doc(user.uid);

    final snapshot = await docUser.get();

    if (!snapshot.exists) {
      await docUser.set({
        'uid': user.uid,
        'name': user.displayName,
        'email': user.email,
        'foto': user.photoURL,
        'role': 'Monitor',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return 'Monitor';
    }

    final data = snapshot.data();
    final role = data?['role']?.toString();

    print("ROL FIRESTORE: $role");

    return role;
  }
}