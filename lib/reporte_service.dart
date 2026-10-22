import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Filtros compartidos por el historial y el archivo Excel.
/// mes: yyyy-MM, o null para todos los meses.
class FiltrosReporte {
  final String? mes;
  final String? seccion;
  final String? grupo;
  const FiltrosReporte({this.mes, this.seccion, this.grupo});
}

class ReporteService {
  static const rutaPlantilla = 'assets/reportes/Machote de reportes.xlsx';

  static DateTime? obtenerFecha(Map<String, dynamic> registro) {
    final valor = registro['fecha'];
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    if (valor is String && valor.trim().isNotEmpty) {
      for (final formato in ['dd/MM/yyyy', 'd/M/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy', 'd-M-yyyy']) {
        try { return DateFormat(formato).parseStrict(valor.trim()); } catch (_) {}
      }
    }
    final envio = registro['fechaEnvio'];
    if (envio is Timestamp) return envio.toDate();
    return null;
  }

  static String texto(Map<String, dynamic> r, String campo) =>
      (r[campo] ?? '').toString().trim();

  static String? mesClave(Map<String, dynamic> r) {
    final fecha = obtenerFecha(r);
    return fecha == null ? null : DateFormat('yyyy-MM').format(fecha);
  }

  static bool coincide(Map<String, dynamic> r, FiltrosReporte f) {
    if (f.mes != null && mesClave(r) != f.mes) return false;
    if (f.seccion != null && texto(r, 'seccion').toLowerCase() != f.seccion!.toLowerCase()) return false;
    if (f.grupo != null && texto(r, 'grupo').toLowerCase() != f.grupo!.toLowerCase()) return false;
    return true;
  }

  static String claveAlumno(Map<String, dynamic> r) {
    final matricula = texto(r, 'matricula');
    if (matricula.isNotEmpty) return 'MAT:$matricula';
    return [texto(r, 'nombre'), texto(r, 'seccion'), texto(r, 'grupo')]
        .join('|').toUpperCase();
  }

  static String claveAlumnoMes(Map<String, dynamic> r) =>
      '${claveAlumno(r)}|${mesClave(r) ?? 'SIN_FECHA'}';

  static Future<List<Map<String, dynamic>>> obtenerHistorialCompleto() async {
    final resultado = <Map<String, dynamic>>[];
    DocumentSnapshot<Map<String, dynamic>>? ultimo;
    while (true) {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance
          .collection('historial_asistencia')
          .orderBy(FieldPath.documentId)
          .limit(400);
      if (ultimo != null) q = q.startAfterDocument(ultimo);
      final pagina = await q.get(const GetOptions(source: Source.server));
      for (final doc in pagina.docs) {
        resultado.add({'id': doc.id, ...doc.data()});
      }
      if (pagina.docs.length < 400) break;
      ultimo = pagina.docs.last;
    }
    return resultado;
  }

  static void escribirTexto(Sheet hoja, int col, int fila, String valor) =>
      hoja.updateCell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: fila), TextCellValue(valor));
  static void escribirNumero(Sheet hoja, int col, int fila, int valor) =>
      hoja.updateCell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: fila), IntCellValue(valor));

  static Future<int> generarYCompartirReporte({
    FiltrosReporte filtros = const FiltrosReporte(),
  }) async {
    await initializeDateFormatting('es_MX');
    final todos = await obtenerHistorialCompleto();
    final registros = todos.where((r) => coincide(r, filtros)).toList();
    registros.sort((a, b) {
      final fa = obtenerFecha(a);
      final fb = obtenerFecha(b);
      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;
      return fb.compareTo(fa);
    });

    final plantilla = await rootBundle.load(rutaPlantilla);
    final excel = Excel.decodeBytes(plantilla.buffer.asUint8List(
        plantilla.offsetInBytes, plantilla.lengthInBytes));
    final bdg = excel['BDG'];
    final grupo = excel['Grupo'];

    final totales = <String, int>{};
    for (final r in registros) {
      final clave = claveAlumnoMes(r);
      totales[clave] = (totales[clave] ?? 0) + 1;
    }

    for (var i = 0; i < registros.length; i++) {
      final r = registros[i];
      final fila = i + 3;
      final fecha = obtenerFecha(r);
      escribirNumero(bdg, 0, fila, i + 1);
      escribirTexto(bdg, 1, fila, texto(r, 'matricula'));
      escribirTexto(bdg, 2, fila, texto(r, 'nombre'));
      escribirTexto(bdg, 3, fila, texto(r, 'seccion'));
      escribirTexto(bdg, 4, fila, texto(r, 'grupo'));
      escribirNumero(bdg, 5, fila, totales[claveAlumnoMes(r)] ?? 0);
      escribirTexto(bdg, 6, fila, fecha == null ? texto(r, 'fecha') : DateFormat('dd/MM/yyyy').format(fecha));
      escribirTexto(bdg, 7, fila, texto(r, 'hora'));
    }

    final resumen = <String, Map<String, dynamic>>{};
    for (final r in registros) {
      final clave = claveAlumnoMes(r);
      resumen.putIfAbsent(clave, () => {
        'seccion': texto(r, 'seccion'),
        'grupo': texto(r, 'grupo'),
        'nombre': texto(r, 'nombre'),
        'mes': obtenerFecha(r) == null ? 'Sin fecha' :
        DateFormat('MMMM yyyy', 'es_MX').format(obtenerFecha(r)!),
        'total': totales[clave] ?? 0,
      });
    }
    final filas = resumen.values.toList()
      ..sort((a, b) {
        final grupoA = '${a['seccion']} ${a['grupo']}';
        final grupoB = '${b['seccion']} ${b['grupo']}';
        final c = grupoA.compareTo(grupoB);
        return c != 0 ? c : '${a['nombre']}'.compareTo('${b['nombre']}');
      });
    for (var i = 0; i < filas.length; i++) {
      final r = filas[i];
      final fila = i + 3;
      escribirNumero(grupo, 0, fila, i + 1);
      escribirTexto(grupo, 1, fila, '${r['seccion']} ${r['grupo']}'.trim());
      escribirTexto(grupo, 2, fila, '${r['nombre']}');
      escribirNumero(grupo, 3, fila, r['total'] as int);
      escribirTexto(grupo, 4, fila, '${r['mes']}');
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('No se pudo generar el Excel');
    final nombre = 'Reporte_GMON_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(Uint8List.fromList(bytes),
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          name: nombre)],
      fileNameOverrides: [nombre],
      subject: 'Reporte GMON filtrado',
    ));
    return registros.length;
  }
}
