import 'package:flutter/material.dart';
import 'package:gmon/auth_services.dart';

import 'home_page.dart';
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPage();
}

class _SignupPage extends State<SignupPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmpasswordController = TextEditingController();
  bool isLoading = false; //tiempo de carga
  bool isPasswordHidden = true;
  bool isCPasswordHidden = true;

  // Instancia por AuthServices con autenticacion de Firebase
  final AuthServices _authServices = AuthServices();
  void _signup()async{
    setState(() {
      isLoading = true;
    });
  // Funcion de registro de usuarios
    // Se llama al metodo de authservices para el registro de usuarios
    String? result = await _authServices.signup(
        name: nameController.text,
        lastname: lastnameController.text,
        email: emailController.text,
        password: passwordController.text
    );
    setState(() {
      isLoading = false;
    });
    if(result == null){
      //Registro exitoso: Navegue a la pantalla de inicio de sesión con el mensaje de éxito.
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Registro exitoso",),
          duration: Duration(seconds: 2),
          ),
      );
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>const HomePage(),),);
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registro Fallido")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image:AssetImage('assets/fondo_registro.jpg'),
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
                          //Caja de texto Nombres y Apellidos
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: "Nombres",
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: 10),

                              Expanded(
                                child: TextField(
                                  controller: lastnameController,
                                  decoration: InputDecoration(
                                    labelText: "Apellidos",
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

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
                                      isPasswordHidden = !isPasswordHidden;
                                    });
                                  },
                                  icon:Icon(isPasswordHidden ?Icons.visibility_off:Icons.visibility,)),
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
                            obscureText: isPasswordHidden,
                          ),
                          //Caja de texto contraseña
                          SizedBox(height: 15),
                          TextField(
                            controller:confirmpasswordController,
                            decoration: InputDecoration(
                              labelText: "Confirmar contraseña:",
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
                          isLoading? const Center(child: CircularProgressIndicator(),):
                          Center(
                            child:SizedBox(
                              width: 250,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B3C66),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                ),
                                child: Text("Crear cuenta",style: TextStyle(
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
                                  "¿Ya tienes cuenta?",
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
                                    "Inicia sesión",
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

