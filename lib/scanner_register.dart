import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:gmon/qr_scanner_widget.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';


class ScannerRegister extends StatefulWidget {
  const ScannerRegister({super.key});

  @override
  State<ScannerRegister> createState() => _ScannerRegisterState();
}

class _ScannerRegisterState extends State<ScannerRegister> {
  bool isConnectedToInternet = true;
  StreamSubscription? _internetConectionStreamSubscription;
  String nombreAlumno = '';
  String seccionAlumno = '';
  String grupoAlumno = '';
  String tutorAlumno = '';
  String fechaActual = '';
  String horaActual = '';

  final player = AudioPlayer();

  bool _isProcessing = false;


  void _clearFields() {
    setState(() {
      nombreAlumno = '';
      seccionAlumno = '';
      grupoAlumno = '';
      tutorAlumno = '';
      fechaActual = '';
      horaActual = '';
      _isProcessing = false; // Reinicia el estado de procesamiento
    });
    // Aquí puedes limpiar los campos después de registrar la información
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
    verificarConexion();

    _internetConectionStreamSubscription =
        InternetConnection().onStatusChange.listen((event) async {
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
    _internetConectionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            //QR Escaneo
            Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: .center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RowInfo(label: 'Fecha', value: '$fechaActual'),
                        RowInfo(label: 'Horas', value: '$horaActual'),
                      ],
                    ),
                    QrScannerWidget(
                      onDetect: (String codigo) async {
                        if (_isProcessing)
                          return; // Evita procesar múltiples códigos al mismo tiempo
                        try {
                          // 1. Convertimos el String a un objeto Map
                          Map<String, dynamic> datos = jsonDecode(codigo);

                          DateTime now = DateTime.now();
                          String fechaFormateada = DateFormat(
                            'dd/MM/yyyy',
                          ).format(now);
                          String horaFormateada = DateFormat('hh:mm a').format(now);

                          //2. Actualizamos el estado con los datos reales del código QR
                          setState(() {
                            _isProcessing =
                            true; // Indica que se está procesando un código
                            fechaActual = fechaFormateada;
                            horaActual = horaFormateada;
                            nombreAlumno = datos['nombre'];
                            seccionAlumno = datos['seccion'];
                            grupoAlumno = datos['grupo'];
                            tutorAlumno = datos['tutor'];
                          });
                          await player.stop();
                          await player.play(AssetSource('beep.mp3'));
                          HapticFeedback.mediumImpact();
                        } catch (e) {
                          print('Debio vibrar por error en el QR');
                          HapticFeedback.heavyImpact();
                        }
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [RowInfo(label: 'Alumno', value: '$nombreAlumno')],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RowInfo(label: 'Sección', value: '$seccionAlumno'),
                        RowInfo(label: 'Grupo', value: '$grupoAlumno'),
                      ],
                    ),
                    RowInfo(label: 'Tutor', value: '$tutorAlumno'),
                    ElevatedButton.icon(
                      onPressed: () {
                        _clearFields();
                      },
                      label: Text('Registrar'),
                      icon: Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RowInfo extends StatelessWidget {
  final String label;
  final String value;

  const RowInfo({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(value, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
