import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'reporte_service.dart';
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
  bool descargandoReporte = false;

  String? mesSeleccionado;
  String? seccionSeleccionada;
  String? grupoSeleccionado;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> historialStream;

  FiltrosReporte get filtros => FiltrosReporte(
    mes: mesSeleccionado,
    seccion: seccionSeleccionada,
    grupo: grupoSeleccionado,
  );

  String mesActual() => DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();

    mesSeleccionado = mesActual();
    historialStream = FirebaseFirestore.instance
        .collection('historial_asistencia').snapshots();
    initializeDateFormatting('es_MX').then((_) { if (mounted) setState(() {}); });
    verificarConexion();

    _internetConectionStreamSubscription =
        InternetConnection().onStatusChange.listen((event) {
          verificarConexion();
        });
  }
  Future<void> descargarReporte() async {
    if (descargandoReporte) return;

    setState(() {
      descargandoReporte = true;
    });

    try {
      final total =
      await ReporteService.generarYCompartirReporte(filtros: filtros);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reporte generado con $total registros.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          descargandoReporte = false;
        });
      }
    }
  }
  // VERIFICAR CONEXIÓN
  Future<void> verificarConexion() async {
    final tieneInternet =
    await InternetConnection().hasInternetAccess;

    if (!mounted) return;

    setState(() {
      isConnectedToInternet = tieneInternet;
    });
  }

  // CERRAR SESIÓN
  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(),
      ),
    );
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
        child: SingleChildScrollView(
          child: Column(
            children: [

              // HEADER
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 15,
                  right: 16,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            "assets/icono_gmon.png",
                            height: 55,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              "GMON",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Monitor - Miravalles",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
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
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isConnectedToInternet
                                  ? "En línea"
                                  : "Sin red",
                              style: TextStyle(
                                color: isConnectedToInternet
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          GestureDetector(
                            onTap: () async {
                              final confirmar =
                              await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) =>
                                    AlertDialog(
                                      title: const Text(
                                        "Cerrar sesión",
                                      ),
                                      content: const Text(
                                        "¿Seguro que deseas salir?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                dialogContext,
                                                false,
                                              ),
                                          child: const Text(
                                            "Cancelar",
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                dialogContext,
                                                true,
                                              ),
                                          child: const Text(
                                            "Salir",
                                          ),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirmar == true) {
                                await cerrarSesion();
                              }
                            },
                            child: const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 32,
                            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                ),
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

              // BUSCADOR (DISEÑO ORIGINAL)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                ),
                child: Row(
                  children:[
                    Text(
                      "Busca dato",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: descargandoReporte
                          ? null
                          : descargarReporte,
                      icon: descargandoReporte
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(
                        Icons.download,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.tune, size: 28),
                  ],
                ),
              ),


              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: historialStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error al cargar historial: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 380,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final todos = snapshot.data!.docs
                      .map((d) => d.data()).toList();
                  final registros = todos
                      .where((r) => ReporteService.coincide(r, filtros))
                      .toList();
                  registros.sort((a, b) {
                    final fa = ReporteService.obtenerFecha(a);
                    final fb = ReporteService.obtenerFecha(b);
                    if (fa == null && fb == null) return 0;
                    if (fa == null) return 1;
                    if (fb == null) return -1;
                    return fb.compareTo(fa);
                  });

                  final meses = todos
                      .map(ReporteService.mesClave)
                      .whereType<String>().toSet().toList()
                    ..sort((a, b) => b.compareTo(a));
                  if (!meses.contains(mesActual())) meses.insert(0, mesActual());

                  final secciones = todos
                      .where((r) => mesSeleccionado == null ||
                      ReporteService.mesClave(r) == mesSeleccionado)
                      .map((r) => ReporteService.texto(r, 'seccion'))
                      .where((v) => v.isNotEmpty).toSet().toList()..sort();

                  final grupos = todos
                      .where((r) => (mesSeleccionado == null ||
                      ReporteService.mesClave(r) == mesSeleccionado) &&
                      (seccionSeleccionada == null ||
                          ReporteService.texto(r, 'seccion') == seccionSeleccionada))
                      .map((r) => ReporteService.texto(r, 'grupo'))
                      .where((v) => v.isNotEmpty).toSet().toList()..sort();

                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Registros enviados',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Enviados: ${registros.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 335,
                      child: registros.isEmpty
                          ? const Center(child: Text('No hay registros con estos filtros',
                          style: TextStyle(fontSize: 18)))
                          : ListView.builder(
                        itemCount: registros.length,
                        itemBuilder: (context, index) {
                          final item = registros[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              const CircleAvatar(radius: 22,
                                  backgroundColor: Color(0xFF36D98A),
                                  child: Icon(Icons.check, color: Colors.white, size: 32)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item['nombre'] ?? ''}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Sección: ${item['seccion'] ?? ''}'),
                                  Text('Grupo: ${item['grupo'] ?? ''}'),
                                  Wrap(spacing: 18, runSpacing: 4, children: [
                                    Text('Fecha: ${item['fecha'] ?? ''}'),
                                    Text('Hora: ${item['hora'] ?? ''}'),
                                  ]),
                                ],
                              )),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF8BE0AA),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Text('Enviado',
                                    style: TextStyle(color: Color(0xFF25A95D), fontWeight: FontWeight.bold)),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(children: [
                        Expanded(child: _FiltroBox(
                          label: 'Mes',
                          value: mesSeleccionado,
                          opciones: meses.map((m) => DropdownMenuItem<String?>(
                            value: m,
                            child: Text('$m'),
                          )).toList(),
                          todosLabel: 'Todos los meses',
                          onChanged: (v) => setState(() {
                            mesSeleccionado = v;
                            seccionSeleccionada = null;
                            grupoSeleccionado = null;
                          }),
                        )),
                        const SizedBox(width: 28),
                        Expanded(child: _FiltroBox(
                          label: 'Grupo', value: grupoSeleccionado,
                          opciones: grupos.map((g) => DropdownMenuItem<String?>(
                              value: g, child: Text(g))).toList(),
                          todosLabel: 'Todos',
                          onChanged: (v) => setState(() => grupoSeleccionado = v),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(children: [
                        _FiltroBox(
                          label: 'Sección', value: seccionSeleccionada,
                          opciones: secciones.map((v) => DropdownMenuItem<String?>(
                              value: v, child: Text(v))).toList(),
                          todosLabel: 'Todas',
                          onChanged: (v) => setState(() {
                            seccionSeleccionada = v;
                            grupoSeleccionado = null;
                          }),
                        ),
                      ]),
                    ),
                  ]);
                },
              ),
              const SizedBox(height: 12),

            ],
          ),
        ),
      ),
    );
  }
}

class _FiltroBox extends StatelessWidget {
  final String label;
  final String? value;
  final String todosLabel;
  final List<DropdownMenuItem<String?>> opciones;
  final ValueChanged<String?> onChanged;

  const _FiltroBox({required this.label, required this.value,
    required this.opciones, required this.onChanged, required this.todosLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 153,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.grey[300],
                borderRadius: BorderRadius.circular(14)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(todosLabel)),
                  ...opciones,
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


