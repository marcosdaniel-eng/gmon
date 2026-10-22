import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Almacenamiento compartido por QR, registro manual y pantalla de pendientes.
class LocalScanStorage {
  static const String key = 'registros_pendientes';

  static Future<void> guardarRegistro(Map<String, dynamic> registro) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(key) ?? <String>[];
    final datos = Map<String, dynamic>.from(registro);
    datos['id'] ??= 'gmon_${DateTime.now().microsecondsSinceEpoch}';
    lista.add(jsonEncode(datos));
    if (!await prefs.setStringList(key, lista)) {
      throw StateError('No se pudo guardar el registro local.');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(key) ?? <String>[];
    bool modificado = false;

    // Recuperar registros creados con la versión anterior de Registro Manual.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final claveAnterior = 'gmon_asistencias_pendientes_$uid';
      final anterior = prefs.getString(claveAnterior);
      if (anterior != null) {
        final registrosAnteriores = jsonDecode(anterior) as List;
        final ids = lista.map((e) => (jsonDecode(e) as Map)['id']?.toString()).toSet();
        for (final item in registrosAnteriores) {
          final registro = Map<String, dynamic>.from(item as Map);
          final id = registro['id']?.toString();
          if (id == null || !ids.contains(id)) {
            lista.add(jsonEncode(registro));
            if (id != null) ids.add(id);
            modificado = true;
          }
        }
        // La clave anterior solo se borra después de persistir la migración.
        if (modificado && !await prefs.setStringList(key, lista)) {
          throw StateError('No se pudo migrar la lista anterior.');
        }
        await prefs.remove(claveAnterior);
      }
    }

    final resultado = <Map<String, dynamic>>[];
    for (var i = 0; i < lista.length; i++) {
      final registro = Map<String, dynamic>.from(jsonDecode(lista[i]) as Map);
      if ((registro['id']?.toString() ?? '').isEmpty) {
        registro['id'] = 'legacy_${DateTime.now().microsecondsSinceEpoch}_$i';
        lista[i] = jsonEncode(registro);
        modificado = true;
      }
      resultado.add(registro);
    }
    if (modificado && !await prefs.setStringList(key, lista)) {
      throw StateError('No se pudieron normalizar los registros locales.');
    }
    return resultado;
  }

  /// Borra solamente los registros que el servidor ya confirmó.
  static Future<void> eliminarPorIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(key) ?? <String>[];
    final restantes = lista.where((texto) {
      final item = jsonDecode(texto) as Map<String, dynamic>;
      return !ids.contains(item['id']?.toString());
    }).toList();
    if (!await prefs.setStringList(key, restantes)) {
      throw StateError('No se pudieron actualizar los registros pendientes.');
    }
  }

  /// Mantiene compatibilidad con el escáner QR existente.
  static Future<void> limpiarRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
