import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  // Instancia con autenticacion de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Instancia con Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  //Función para gestionar el registro de usuarios
  Future <String?> signup({
    required String name,
    required String lastname,
    required String email,
    required String password,
    String role="Monitor",
  }) async{
    try{
      //Creación de usuario en Firebase con Correo electrónico y contraseña
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
      );
      print("Usuario creado");
      // Guarda datos adicionales del usuario en Firestores como Nombres, Apellidos, Correo electrónico y rol)
      await _firestore
          .collection("usuarios")
          .doc(userCredential.user!.uid)
          .set({
            "name":name.trim(),
            "lastname":lastname.trim(),
            "email":email.trim(),
            "role":role, // se determina si es administrador o usuario
      });
      return null; // Situación erronea
    }catch (e) {
      return e.toString();
    }
  }

  // Función para Recuperar cuenta
  Future <String?> sendResetLink({
    required String email,
}) async{
    try {
      await _auth.sendPasswordResetEmail(email: email);
    }on FirebaseAuthException{
      rethrow;
    }
  }

  // //Función para gestionar el inicio de usuarios
  Future <String?> login({
    required String email,
    required String password,
  }) async{
    try{
      //Inicio de sesión de usuario en Firebase con Correo electrónico y contraseña
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      //Obtener el rol del usuario desde Firestore para determinar el nivel de acceso.
      DocumentSnapshot userDoc = await _firestore
          .collection("usuarios")
          .doc(userCredential.user!.uid)
          .get();
      return userDoc['role']; //regresa el rol del usuario
    }catch(e){
      return e.toString();
    }
  }
}