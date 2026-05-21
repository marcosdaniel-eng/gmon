import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalScanStorage {
  static const String key = 'registros_pendientes';

  static Future<void> guardarRegistro(Map<String, dynamic> registro) async {
    final prefs = await SharedPreferences.getInstance();

    final lista = prefs.getStringList(key) ?? [];
    lista.add(jsonEncode(registro));

    await prefs.setStringList(key, lista);
  }

  static Future<List<Map<String, dynamic>>> obtenerRegistros() async {
    final prefs = await SharedPreferences.getInstance();

    final lista = prefs.getStringList(key) ?? [];

    return lista
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }
}