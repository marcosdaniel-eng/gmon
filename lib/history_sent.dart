import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'home_page.dart';

class HistorySent extends StatefulWidget {
  const HistorySent({super.key});

  @override
  State<HistorySent> createState() => _HistorySentState();
}

class _HistorySentState extends State<HistorySent> {
  bool isConnectedToInternet = true;
  StreamSubscription? _internetConectionStreamSubscription;

  @override
  void initState() {
    super.initState();
    verificarConexion();

    _internetConectionStreamSubscription =
        InternetConnection().onStatusChange.listen((event) {
          verificarConexion();
        });
  }

  Future<void> verificarConexion() async {
    final tieneInternet = await InternetConnection().hasInternetAccess;

    if (!mounted) return;

    setState(() {
      isConnectedToInternet = tieneInternet;
    });
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
  void dispose() {
    _internetConectionStreamSubscription?.cancel();
    super.dispose();
  }

  final registros = [

  ];

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

            const SizedBox(height: 8),

            // BOTÓN REGRESAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // TITULOS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Registros enviados",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('historial_asistencia')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final total = snapshot.data?.docs.length ?? 0;

                      return Text(
                        "Enviados: $total",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // LISTA
            SizedBox(
              height: 335,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('historial_asistencia')
                    .orderBy('fechaEnvio', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No hay registros enviados",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  final registros = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: registros.length,
                    itemBuilder: (context, index) {

                      final item =
                      registros[index].data() as Map<String, dynamic>;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 7,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0xFF36D98A),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nombre'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),

                                  Text(
                                    "Sección: ${item['seccion'] ?? ''}",
                                  ),

                                  Text(
                                    "Grupo: ${item['grupo'] ?? ''}",
                                  ),

                                  Wrap(
                                    spacing: 18,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        "Fecha: ${item['fecha'] ?? ''}",
                                      ),
                                      const SizedBox(width: 18),
                                      Text(
                                        "Hora: ${item['hora'] ?? ''}",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8BE0AA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Enviado",
                                style: TextStyle(
                                  color: Color(0xFF25A95D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // BUSCADOR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: const [
                  Text(
                    "Busca dato",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Spacer(),
                  Icon(Icons.download, size: 28),
                  SizedBox(width: 16),
                  Icon(Icons.tune, size: 28),
                ],
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Expanded(child: _FiltroBox(label: "Mes")),
                  SizedBox(width: 28),
                  Expanded(child: _FiltroBox(label: "Grupo")),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: const [
                  _FiltroBox(label: "Sección"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltroBox extends StatelessWidget {
  final String label;

  const _FiltroBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 153,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Text("Todos"),
                Spacer(),
                Icon(Icons.keyboard_arrow_down, size: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
