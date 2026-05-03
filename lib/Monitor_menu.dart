import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gmon/home_page.dart';
import 'package:gmon/scanner_register.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class Monitor_menu extends StatefulWidget {
  const Monitor_menu({super.key});

  @override
  State<Monitor_menu> createState() => _Monitor_menuState();
}

class _Monitor_menuState extends State<Monitor_menu> {
  bool isConnectedToInternet = false;
  StreamSubscription? _internetConectionStreamSubscription;
  String nombreUsuario = "";
// Funcion nombre  de usuario
  Future<void> obtenerUsuario() async{
    try{
      User? user = FirebaseAuth.instance.currentUser;
      if(user !=null){
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection("usuarios")
            .doc(user.uid)
            .get();
        setState(() {
          nombreUsuario = doc["name"];
        });
      }

    }catch(e){
      print("Error $e");
    }
  }

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
    initializeDateFormatting('es');
    obtenerUsuario();
    _internetConectionStreamSubscription = InternetConnection().onStatusChange.listen((event){
      switch (event){
        case InternetStatus.connected:
          setState(() {
            isConnectedToInternet = true;
          });
          break;
        case InternetStatus.disconnected:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
          default:
           setState(() {
             isConnectedToInternet = false;
           });
            break;
      }
    });
  }
  @override
  void dispose() {
    _internetConectionStreamSubscription?.cancel();
    super.dispose();
  }

  Map<String,dynamic> getSaludo(){
    int hora = DateTime.now().hour;

    if(hora<12){
      return{
        "texto":"¡Buenos días!",
        "icono": Icons.wb_sunny,
        "color": Colors.orange,
        "image": "assets/buenos_dias.jpg",
      };
    } else if (hora < 18){
      return {
      "texto":"¡Buenas tardes!",
      "icono": Icons.wb_cloudy,
      "color": Colors.blue,
        "image": "assets/buenas_tardes.jpg",
     };
    }else{
      return {
        "texto":"¡Buenas noches!",
        "icono": Icons.nightlight_round,
        "color": Colors.indigo,
        "image": "assets/buenas_noches.jpg",
      };
    }
  }

// Interfaz
  @override
  Widget build(BuildContext context) {
    var saludo = getSaludo();
    String getFecha() {
      final now = DateTime.now();
      final formatter = DateFormat("EEEE d 'de' MMMM 'del' yyyy", "es");
      return formatter.format(now);
    }
    return Scaffold(
      body: SafeArea(
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
                  Row(
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
                      Text(
                        isConnectedToInternet ? "En línea" : "Sin red",
                        style: TextStyle(
                          color: isConnectedToInternet
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
            
            //Saludo dinamico
            Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  // IMAGEN DE FONDO
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: AssetImage(saludo["image"]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // FECHA (ARRIBA)
                  Positioned(
                    left: 15,
                    top: 10,
                    child: Text(
                      getFecha(),
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 16 ,
                      ),
                    ),
                  ),

                  // SALUDO + ICONO (ABAJO)
                  Positioned(
                    left: 15,
                    top: 54,
                    child: Row(
                      children: [
                        Icon(
                          saludo["icono"],
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "${saludo["texto"]} $nombreUsuario", // Nombre del monitor con Firestore
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black54,
                                offset: Offset(2, 2),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Texto que quieres hacer hoy
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "¿Qué quieres hacer hoy?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            //botones de opciones
            Padding(
                padding:const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                Row(
                  children: [
                      Expanded(child: buildOptionCard( context,
                          "Escanear",
                          "assets/ESCANEAR.png",
                          Colors.blue
                        ),
                      ),
                    SizedBox(width: 10,),
                    Expanded(child: buildOptionCard( context,
                        "Pendientes",
                        "assets/ALERT.png",
                        Colors.pink
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: buildOptionCard( context,
                        "Asistencia",
                        "assets/SUPPORT.png",
                        Colors.green
                     ),
                    ),
                    SizedBox(width: 10,),
                    Expanded(child: buildOptionCard( context,
                        "Historial",
                        "assets/REPORT.png",
                        Colors.purple,
                      ),
                     ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// CARD BOTONES
Widget buildOptionCard(BuildContext context,
    String title, String image, Color color) {
  return GestureDetector(
      onTap: () {
        if(title == 'Escanear'){
          Navigator.pushReplacement(
            context,
              MaterialPageRoute(
                  builder: (_)=> const ScannerRegister(),
              )
          );// un if para el cambio de pantalla
        }
      },
    child: Container(
    height: 140,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color, width: 2),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(image, height: 90),
        SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}


