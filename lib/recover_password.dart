import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gmon/auth_services.dart';

import 'home_page.dart';
class RecoverPassword extends StatefulWidget {
  const RecoverPassword({super.key});

  @override
  State<RecoverPassword> createState() => _RecoverPassword();
}

class _RecoverPassword extends State<RecoverPassword> {
  TextEditingController emailController = TextEditingController();
  bool isLoading = false; //tiempo de carga
  // Funcion para recuperar contraseña
  final AuthServices _authServices = AuthServices();

  Future reset()async{
    setState(() {
      isLoading = true;
    });
    try{
      await _authServices.sendResetLink(email: emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Se envío correo electronico de restablecimiento.")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:(_) => const HomePage(),
        ),
      );
    }catch(e){
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image:AssetImage('assets/fondo_recover.jpg'),
            fit:BoxFit.cover,
          ),
        ),

        child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                     width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.75,
                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Text(
                              "Recuperar contraseña",
                              style: TextStyle(fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B3C66),
                              )
                          ),
                          SizedBox(height: 30,),
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

                          //Boton de inicio de sesión
                          const SizedBox(height: 20),
                          Center(
                            child:SizedBox(
                              width: 250,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: reset,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B3C66),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                ),
                                child: Text("Envíar",style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              Text(
                                  "¿Aún no tienes cuenta?",
                                  style: TextStyle(fontSize: 17,
                                    color: Colors.blue[350],
                                  )
                              ),
                              InkWell(
                                onTap:(){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:(_) => const HomePage(),
                                    ),
                                  );
                                },
                                child: Text(
                                    "Crea una",
                                    style: TextStyle(fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[350],
                                    )
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

