import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:gmon/register_manually.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gmon/Monitor_menu.dart';
import 'package:gmon/without_sending.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:gmon/qr_scanner_widget.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'local_scan_storage.dart';


class ScannerRegister extends StatefulWidget {
  const ScannerRegister({super.key});

  @override
  State<ScannerRegister> createState() => _ScannerRegisterState();
}

class _ScannerRegisterState extends State<ScannerRegister> {
  bool isConnectedToInternet = true;
  bool mostrarAvisoManual = true;
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
  Future<void> registrarPendiente() async {
    if (nombreAlumno.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Primero escanea un QR"),
        ),
      );
      return;
    }

    final registro = {
      'nombre': nombreAlumno,
      'seccion': seccionAlumno,
      'grupo': grupoAlumno,
      'tutor': tutorAlumno,
      'fecha': fechaActual,
      'hora': horaActual,
      'sincronizado': false,
    };

    await LocalScanStorage.guardarRegistro(registro);

    if (!mounted) return;

    _clearFields();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const WithoutSending(),
      ),
    );
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
    player.dispose();
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

            //QR Escaneo
            //Fecha y hora
            Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [

                            // FECHA
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Color(0xFF0B3D5C),
                                    size: 30,
                                  ),

                                  const SizedBox(width: 10),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Fecha:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        fechaActual,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // SEPARADOR
                            Container(
                              width: 1,
                              height: 45,
                              color: Colors.grey[300],
                            ),

                            const SizedBox(width: 15),

                            // HORA
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Color(0xFF0B3D5C),
                                    size: 30,
                                  ),

                                  const SizedBox(width: 10),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hora:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        horaActual,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    //Camara
                    QrScannerWidget(
                      onDetect: (String codigo) async {
                        if (_isProcessing) return;

                        setState(() {
                          _isProcessing = true;
                        }); // Evita procesar múltiples códigos al mismo tiempo
                        try {
                          // 1. Convertimos el String a un objeto Map
                          Map<String, dynamic> datos = jsonDecode(codigo);

                          DateTime now = DateTime.now();
                          //2. Actualizamos el estado con los datos reales del código QR
                          setState(() {
                            fechaActual =  DateFormat('dd/MM/yyyy',).format(now);
                            horaActual =  DateFormat('hh:mm a').format(now);
                            nombreAlumno = datos['nombre'];
                            seccionAlumno = datos['seccion'];
                            grupoAlumno = datos['grupo'];
                            tutorAlumno = datos['tutor'];
                          });
                          await player.stop();
                          await player.play(AssetSource("beep.mp3"));
                          await HapticFeedback.mediumImpact();

                          await Future.delayed(const Duration(milliseconds: 200));
                        } catch (e) {
                          print('Error QR: $e');
                        }
                        if (mounted){
                          setState(() {
                            _isProcessing = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RowInfo(
                            icon: Icons.person_outline,
                            label: 'Alumno',
                            value: nombreAlumno,
                          ),

                          RowInfo(
                            icon: Icons.school_outlined,
                            label: 'Sección',
                            value: seccionAlumno,
                          ),

                          RowInfo(
                            icon: Icons.groups_outlined,
                            label: 'Grupo',
                            value: grupoAlumno,
                          ),

                          RowInfo(
                            icon: Icons.supervisor_account_outlined,
                            label: 'Tutor',
                            value: tutorAlumno,
                          ),
                        ],
                      ),
                    ),
                    //Boton de enviar
                    SizedBox(
                      width: 250,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: registrarPendiente,
                        icon: const Icon(
                          Icons.near_me_outlined,
                          color: Colors.black,
                          size: 30,
                        ),
                        label: const Text(
                          'Registrar',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2EEA73),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          ),
                        ),
                      ),

                    if(mostrarAvisoManual) ...[
                      const SizedBox(height: 12),

                      Container(
                        width: 320,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF9EF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF8BD9A5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 19,
                              backgroundColor: Color(0xFF2EEA73),
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 23,
                              ),
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Registro manual',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text('Usalo cuando el alumno no traiga su credencial para hacer la búsqueda manual.',
                                    style: TextStyle(fontSize: 12,
                                    color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                )
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                                onPressed:(){
                                  setState(() {
                                    mostrarAvisoManual = false;
                                  });
                                },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black87,
                                size: 22,
                              ),
                              tooltip: 'Cerrar aviso',
                            )
                          ],
                        ),
                      )
                    ],

                    const SizedBox(height: 12,),
                    // Botón registrar manual
                    SizedBox(
                        width: 250,
                        height: 52,
                        child: OutlinedButton.icon(
                            onPressed:() {
                              Navigator.push(context,
                                MaterialPageRoute(
                                  builder: (_) => const ManualRegister(),
                                  ),
                                );
                            },
                            icon: const Icon(
                              Icons.person_search_outlined,
                              color: Color(0xFF20B85A),
                              size: 28,
                            ),
                            label: const Text(
                              'Registro manual',
                              style: TextStyle(
                                color: Color(0xFF20B85A),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFF20B85A),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              )
                            ),
                          ),
                      ),
                    ],
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

class RowInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const RowInfo({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Iconos
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0B3D5C).withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0B3D5C),
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
