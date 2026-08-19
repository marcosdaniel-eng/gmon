import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gmon/Monitor_menu.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'home_page.dart';
import 'local_scan_storage.dart';

class WithoutSending extends StatefulWidget {
  const WithoutSending({super.key});

  @override
  State<WithoutSending> createState() => _WithoutSendingState();
}

class _WithoutSendingState extends State<WithoutSending> {
  List<Map<String, dynamic>> registros = [];
  bool isConnectedToInternet = true;
  StreamSubscription? _internetConectionStreamSubscription;
  bool isSending = false;

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
    cargarRegistros();
    verificarConexion();

    _internetConectionStreamSubscription =
        InternetConnection().onStatusChange.listen((event) async {
          verificarConexion();
       });
  }

  // Funcion de Registros locales
  Future<void> cargarRegistros() async {
    final data = await LocalScanStorage.obtenerRegistros();

    setState(() {
      registros = data;
    });
  }
 // Funcion de conectividad a red
  Future<void> verificarConexion() async {
    final tieneInternet =
    await InternetConnection().hasInternetAccess;

    if (!mounted) return;
    setState(() {
      isConnectedToInternet = tieneInternet;
    });
  }

  Future<void> enviarRegistros() async {
    if (!isConnectedToInternet || registros.isEmpty || isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final registro in registros) {
        final docRef = FirebaseFirestore.instance
            .collection("registros_retardos")
            .doc();

        batch.set(docRef, {
          ...registro,
          'sincronizado': true,
          'fechaEnvio': FieldValue.serverTimestamp(),
        });
        final historialRef = FirebaseFirestore.instance
          .collection("historial_asistencia")
          .doc();

        batch.set(historialRef,{
          ...registro,
          'fechaEnvio':FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      await LocalScanStorage.limpiarRegistros();
      await cargarRegistros();

      if (!mounted) return;

      setState(() {
        registros.clear();
        isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registros enviados correctamente")),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar: $e")),
      );
    }
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
            // Lista de pendientes
            const SizedBox(height: 15),

            Text(
              "Registros pendientes: ${registros.length}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
      const SizedBox(height: 10),

      Expanded(
        child: registros.isEmpty
            ? const Center(
          child: Text(
            "No hay registros pendientes",
            style: TextStyle(fontSize: 18),
              ),
            )
            : ListView.builder(
          itemCount: registros.length,
          itemBuilder: (context, index) {
            final item = registros[index];

            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(14)
                    ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 23,
                    backgroundColor: Color(0xFFFF5C75),
                    child: Icon(Icons.priority_high,color: Colors.white,size: 32,
                    ),
                  ),
                  const SizedBox(width: 12,),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nombre'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text("Sección: ${item['seccion']??''}"),
                        Text("Grupo: ${item['grupo']??''}"),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text("Fecha: ${item['fecha']??''}"),
                            const SizedBox(width: 20),
                            Text("Hora: ${item['hora']??''}"),
                          ],
                        ),
                      ],
                    )
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9AA8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Pendiente",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              );
              },
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: SizedBox(
                width: 220,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: isConnectedToInternet &&
                      registros.isNotEmpty &&
                      !isSending
                      ? enviarRegistros
                      : null,
                  icon: isSending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                      : const Icon(
                    Icons.near_me_outlined,
                    color: Colors.black,
                  ),
                  label: Text(
                    isSending ? "Enviando..." : "Enviar",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EEA73),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
