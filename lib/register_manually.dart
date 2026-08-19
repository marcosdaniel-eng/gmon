import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'Monitor_menu.dart';
import 'home_page.dart';


class ManualRegister extends StatefulWidget {
  const ManualRegister({super.key});

  @override
  State<ManualRegister> createState() => _ManualRegisterState();
}

class _ManualRegisterState extends State<ManualRegister> {
  //Variables de internet
  bool isConnectedToInternet = true;
  StreamSubscription? _internetConectionStreamSubscription;
  //Variables de buscar
  final TextEditingController buscarController = TextEditingController();

  //Funcion de cierre de sesion
  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage()), // tu login
    );
  }

  @override
  void initState() {
    super.initState();
    // Revisa la conexión apenas abre la pantalla
    verificarConexion();

    // Realiza el cambio cuando la conexión cambia
    _internetConectionStreamSubscription =
        InternetConnection().onStatusChange.listen((event) {
          verificarConexion();
        });
  }

  Future<void> verificarConexion() async {
    final tieneInternet =
    await InternetConnection().hasInternetAccess;

    if (!mounted) return;

    setState(() {
      isConnectedToInternet = tieneInternet;
    });
  }
  @override
  void dispose() {
    buscarController.dispose();
    _internetConectionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // 🔹 HEADER
              Padding(
                padding: EdgeInsets.only(left: 16, top: 15, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // IZQUIERDA
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          child: Image.asset("assets/icono_gmon.png",height: 55,),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("GMON",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Monitor - Miravalles",
                                style: TextStyle(fontSize: 14)),
                          ],
                        )
                      ],
                    ),

                    // DERECHA
                    Flexible(
                      child:Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isConnectedToInternet
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isConnectedToInternet
                                  ? Icons.wifi
                                  : Icons.wifi_off,
                              color: isConnectedToInternet
                                  ? Colors.green
                                  : Colors.red,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child:Text(
                              isConnectedToInternet ? "En línea" : "Sin red",
                              style: TextStyle(
                                color: isConnectedToInternet
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          //Cierre de sesion
                          GestureDetector(
                            onTap: () async {
                              bool? confirmar = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Cerrar sesión"),
                                  content: Text("¿Seguro que deseas salir?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text("Cancelar"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text("Salir"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmar == true) {
                                cerrarSesion();
                              }
                            },
                            child: Icon(Icons.logout, color: Colors.red, size: 32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10,),
              //Boton de regresar a pantalla anterior
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child:Row(
                  children: [
                    GestureDetector(
                      onTap: (){
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Monitor_menu(),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF0B3D5C),
                          size: 18,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 25),
              //Front de barra buscar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: TextField(
                  controller: buscarController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar alumno...',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF0B3D5C),
                      size: 28,
                    ),
                    suffixIcon: buscarController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        buscarController.clear();
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                      ),
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF0B3D5C),
                        width: 2,
                      ),
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



