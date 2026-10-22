import 'dart:async';
import 'dart:convert';
import 'local_scan_storage.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Monitor_menu.dart';
import 'home_page.dart';

class ManualRegister extends StatefulWidget {
  const ManualRegister({super.key});

  @override
  State<ManualRegister> createState() => _ManualRegisterState();
}

class _ManualRegisterState extends State<ManualRegister> {
  static const Color azul = Color(0xFF0B3D5C);
  static const Color dorado = Color(0xFFEFB810);

  final TextEditingController buscarController = TextEditingController();
  StreamSubscription<InternetStatus>? _conexionSubscription;
  bool isConnectedToInternet = true;
  bool cargandoAlumnos = true;
  bool sincronizando = false;
  bool registrando = false;
  String? errorCatalogo;
  String filtroSeleccionado = 'Todos';
  String? matriculaSeleccionada;
  List<Map<String, dynamic>> alumnos = [];
  DateTime ahora = DateTime.now();
  Timer? _reloj;

  String get _claveCache {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'sin_usuario';
    return 'gmon_alumnos_$uid';
  }

  Future<void> _registrarAlumno() async {
    if (registrando || matriculaSeleccionada == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Necesitas iniciar sesión para registrar asistencia.'),
      ));
      return;
    }
    final encontrados = alumnos.where((a) =>
    a['matricula'].toString() == matriculaSeleccionada).toList();
    if (encontrados.isEmpty) return;
    final alumno = encontrados.first;
    setState(() => registrando = true);
    try {
      final fechaRegistro = DateTime.now();
      final id = '${user.uid}_${alumno['matricula']}_${fechaRegistro.microsecondsSinceEpoch}';
      final registro = <String, dynamic>{
        'id': id,
        'matricula': alumno['matricula'].toString(),
        'nombre': alumno['nombre'].toString(),
        'seccion': alumno['seccion'].toString(),
        'grupo': alumno['grupo'].toString(),
        'tutor': alumno['tutor'].toString(),
        'fecha': DateFormat('dd/MM/yyyy').format(fechaRegistro),
        'hora': DateFormat('hh:mm a').format(fechaRegistro),
        'fechaRegistro': fechaRegistro.toIso8601String(),
        'registradoPor': user.uid,
        'origen': 'manual',
        'sincronizado': false,
      };
      await LocalScanStorage.guardarRegistro(registro);
      if (!mounted) return;
      setState(() => matriculaSeleccionada = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Asistencia guardada. Ya aparece en Registros pendientes.'),
      ));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo guardar la asistencia. Intenta nuevamente.'),
      ));
    } finally {
      if (mounted) setState(() => registrando = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => ahora = DateTime.now());
    });
    _iniciarCatalogo();
    _conexionSubscription = InternetConnection().onStatusChange.listen((estado) {
      if (!mounted) return;
      final conectado = estado == InternetStatus.connected;
      final antes = isConnectedToInternet;
      setState(() => isConnectedToInternet = conectado);
      if (conectado && !antes) {
        _sincronizarCatalogo();
      }
    });
  }

  Future<void> _iniciarCatalogo() async {
    await _cargarCache();
    if (mounted) setState(() => cargandoAlumnos = false);
    await _sincronizarCatalogo();
  }

  Future<void> _cargarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_claveCache);
      if (texto == null) return;
      final datos = jsonDecode(texto) as List<dynamic>;
      final lista = datos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) setState(() => alumnos = lista);
    } catch (e) {
      if (mounted) setState(() => errorCatalogo = 'No se pudo leer el catálogo local.');
    }
  }

  Future<void> _sincronizarCatalogo() async {
    if (sincronizando || FirebaseAuth.instance.currentUser == null) return;
    setState(() {
      sincronizando = true;
      errorCatalogo = null;
    });
    try {
      // Se solicita al servidor el catálogo completo; solo se reemplaza
      // la copia local cuando la consulta finaliza correctamente.
      final snapshot = await FirebaseFirestore.instance
          .collection('alumnos')
          .get(const GetOptions(source: Source.server));
      final lista = snapshot.docs.map((doc) {
        final d = doc.data();
        return <String, dynamic>{
          'matricula': (d['matricula'] ?? doc.id).toString(),
          'nombre': (d['nombre'] ?? '').toString(),
          'seccion': (d['seccion'] ?? '').toString(),
          'grupo': (d['grupo'] ?? '').toString(),
          'tutor': (d['tutor'] ?? '').toString(),
        };
      }).where((a) => a['matricula']!.isNotEmpty).toList();

      // Evita borrar un catálogo previamente guardado si el servidor
      // devuelve una colección vacía inesperadamente.
      if (lista.isEmpty) {
        throw StateError('La colección alumnos está vacía.');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveCache, jsonEncode(lista));
      if (mounted) setState(() => alumnos = lista);
    } catch (_) {
      if (mounted && alumnos.isEmpty) {
        setState(() => errorCatalogo =
        'No hay alumnos disponibles. Conéctate a internet para descargar el catálogo por primera vez.');
      }
    } finally {
      if (mounted) setState(() => sincronizando = false);
    }
  }

  String _normalizar(String texto) {
    const origen = 'áéíóúüñÁÉÍÓÚÜÑ';
    const destino = 'aeiouunAEIOUUN';
    var valor = texto;
    for (var i = 0; i < origen.length; i++) {
      valor = valor.replaceAll(origen[i], destino[i]);
    }
    return valor.toLowerCase().trim();
  }

  List<Map<String, dynamic>> get resultados {
    final q = _normalizar(buscarController.text);
    if (q.isEmpty) return [];
    final campos = <String, List<String>>{
      'Todos': ['nombre', 'matricula', 'grupo', 'seccion'],
      'Nombre': ['nombre'],
      'Matrícula': ['matricula'],
      'Grupo': ['grupo'],
      'Sección': ['seccion'],
    };
    final activos = campos[filtroSeleccionado] ?? campos['Todos']!;
    final encontrados = alumnos.where((alumno) => activos.any(
          (campo) => _normalizar(alumno[campo]?.toString() ?? '').contains(q),
    )).toList();
    encontrados.sort((a, b) => (a['nombre'] ?? '').toString()
        .compareTo((b['nombre'] ?? '').toString()));
    return encontrados;
  }

  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
    );
  }

  Widget _botonFiltro(String texto, IconData icono) {
    final seleccionado = filtroSeleccionado == texto;
    return GestureDetector(
      onTap: () => setState(() {
        filtroSeleccionado = texto;
        matriculaSeleccionada = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: seleccionado ? azul : Colors.transparent,
          border: Border.all(color: seleccionado ? azul : dorado, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono, size: 18, color: seleccionado ? Colors.white : azul),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(
            color: seleccionado ? Colors.white : azul,
            fontWeight: FontWeight.bold, fontSize: 13,
          )),
        ]),
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    return partes.take(2).map((p) => p[0]).join().toUpperCase();
  }

  Widget _tarjetaAlumno(Map<String, dynamic> alumno) {
    final matricula = alumno['matricula']?.toString() ?? '';
    final nombre = alumno['nombre']?.toString() ?? '';
    final seleccionado = matriculaSeleccionada == matricula;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: seleccionado ? Colors.green : Colors.grey.shade300),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFE4EEF5),
          child: Text(_iniciales(nombre), style: const TextStyle(
            color: azul, fontWeight: FontWeight.bold, fontSize: 16,
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Matrícula: $matricula', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text('${alumno['seccion']} • Grupo: ${alumno['grupo']}',
                style: const TextStyle(fontSize: 12)),
          ],
        )),
        const SizedBox(width: 5),
        OutlinedButton(
          onPressed: () => setState(() => matriculaSeleccionada = matricula),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            side: BorderSide(color: seleccionado ? Colors.green : azul),
            backgroundColor: seleccionado ? Colors.green : Colors.white,
          ),
          child: Text(seleccionado ? 'Elegido' : 'Elegir',
              style: TextStyle(color: seleccionado ? Colors.white : azul, fontSize: 12)),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _conexionSubscription?.cancel();
    buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final encontrados = resultados;
    final hayBusqueda = buscarController.text.trim().isNotEmpty;
    final seleccionado = matriculaSeleccionada != null;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
              child: Row(children: [
                Image.asset('assets/icono_gmon.png', height: 55),
                const SizedBox(width: 10),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GMON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Monitor - Miravalles', style: TextStyle(fontSize: 13)),
                  ],
                )),
                Icon(isConnectedToInternet ? Icons.wifi : Icons.wifi_off,
                    color: isConnectedToInternet ? Colors.green : Colors.red),
                const SizedBox(width: 4),
                Text(isConnectedToInternet ? 'En línea' : 'Sin red',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                        color: isConnectedToInternet ? Colors.green : Colors.red)),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cerrar sesión'),
                        content: const Text('¿Seguro que deseas salir?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Salir')),
                        ],
                      ),
                    );
                    if (confirmar == true) await cerrarSesion();
                  },
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Align(alignment: Alignment.centerLeft, child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: azul),
                style: IconButton.styleFrom(backgroundColor: Colors.grey.shade300),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const Monitor_menu()));
                  }
                },
              )),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: TextField(
                controller: buscarController,
                onChanged: (_) => setState(() => matriculaSeleccionada = null),
                decoration: InputDecoration(
                  hintText: 'Buscar alumno...',
                  prefixIcon: const Icon(Icons.search, color: azul, size: 28),
                  suffixIcon: buscarController.text.isEmpty ? null : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      buscarController.clear();
                      matriculaSeleccionada = null;
                    }),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: azul, width: 2)),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: Text('Filtros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Wrap(spacing: 8, runSpacing: 10, children: [
                _botonFiltro('Todos', Icons.apps),
                _botonFiltro('Nombre', Icons.person_outline),
                _botonFiltro('Matrícula', Icons.badge_outlined),
                _botonFiltro('Grupo', Icons.groups_outlined),
                _botonFiltro('Sección', Icons.school_outlined),
              ]),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300)),
                child: Row(children: [
                  const Icon(Icons.calendar_month_outlined, color: azul),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(DateFormat('dd/MM/yyyy').format(ahora),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, color: azul),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hora', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(DateFormat('hh:mm a').format(ahora),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(children: [
                const Icon(Icons.groups_outlined, color: azul),
                const SizedBox(width: 8),
                const Text('Resultados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${encontrados.length} resultado${encontrados.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: azul, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 12),
            if (cargandoAlumnos && alumnos.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (errorCatalogo != null && alumnos.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(errorCatalogo!, textAlign: TextAlign.center))
            else if (!hayBusqueda)
                const Padding(padding: EdgeInsets.symmetric(horizontal: 28),
                    child: Text('Escribe un nombre, matrícula, grupo o sección para buscar.',
                        style: TextStyle(color: Colors.grey)))
              else if (encontrados.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Text('No se encontraron alumnos.'))
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(children: encontrados.map(_tarjetaAlumno).toList()),
                  ),
            if (alumnos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                child: Text('${alumnos.length} Alumnos disponibles en el curso${sincronizando ? ' · Actualizando...' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            const SizedBox(height: 18),
            if (seleccionado)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => matriculaSeleccionada = null),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Limpiar selección',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size.fromHeight(50)),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ElevatedButton.icon(
                onPressed: seleccionado && !registrando ? _registrarAlumno : null,
                icon: const Icon(Icons.near_me_outlined, color: Colors.white),
                label: const Text('Registrar', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const SizedBox(height: 18),
          ]),
        ),
      ),
    );
  }
}





