import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/operacion_pendiente_dto.dart';

class OfflineQueueService {
  static const _boxName = 'offline_queue';

  Box<Map<dynamic, dynamic>>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  Box<Map<dynamic, dynamic>> get _b {
    if (_box == null) throw StateError('OfflineQueueService no inicializado');
    return _box!;
  }

  List<OperacionPendiente> get cola {
    return _b.values.map((raw) {
      final m = raw;
      return OperacionPendiente(
        id: m['id'] as String,
        tabla: m['tabla'] as String,
        operacion: m['operacion'] as String,
        datos: Map<String, dynamic>.from(m['datos'] as Map),
        creadoEn: DateTime.parse(m['creadoEn'] as String),
        identificador: m['identificador'] as String?,
        reintentos: (m['reintentos'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<void> encolar({
    required String tabla,
    required String operacion,
    required Map<String, dynamic> datos,
    String? identificador,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _b.add({
      'id': id,
      'tabla': tabla,
      'operacion': operacion,
      'datos': datos,
      'creadoEn': DateTime.now().toIso8601String(),
      'identificador': identificador,
      'reintentos': 0,
    });
  }

  Future<void> eliminar(int indice) async {
    await _b.deleteAt(indice);
  }

  Future<void> incrementarReintentos(int indice, int reintentosActuales) async {
    final raw = _b.getAt(indice);
    if (raw == null) return;
    final m = Map<String, dynamic>.from(raw);
    m['reintentos'] = reintentosActuales + 1;
    await _b.putAt(indice, m);
  }

  Future<void> limpiar() async {
    await _b.clear();
  }

  int get longitud => _b.length;

  /// Obtiene una entrada raw de la cola en un indice dado.
  /// Utilizado por el motor de merge para iterar sin deserializar.
  Map<dynamic, dynamic>? getRawAt(int index) {
    if (index < 0 || index >= _b.length) return null;
    return _b.getAt(index);
  }

  Future<void> procesarCola() async {
    final client = Supabase.instance.client;
    var i = 0;

    while (i < _b.length) {
      final raw = _b.getAt(i);
      if (raw == null) {
        i++;
        continue;
      }

      final m = Map<String, dynamic>.from(raw);
      final reintentos = (m['reintentos'] as num?)?.toInt() ?? 0;

      if (reintentos >= OperacionPendiente.maxReintentos) {
        await _b.deleteAt(i);
        continue;
      }

      try {
        final op = m['operacion'] as String;
        final tabla = m['tabla'] as String;
        final datos = Map<String, dynamic>.from(m['datos'] as Map);

        switch (op) {
          case 'INSERT':
            await client.from(tabla).insert(datos);
            break;
          case 'UPDATE':
            final idUpd = m['identificador'] as String?;
            if (idUpd != null) {
              await client.from(tabla).update(datos).eq('id', idUpd);
            }
            break;
          case 'DELETE':
            final idDel = m['identificador'] as String?;
            if (idDel != null) {
              await client.from(tabla).delete().eq('id', idDel);
            }
            break;
        }

        await _b.deleteAt(i);
      } catch (_) {
        await incrementarReintentos(i, reintentos);
        i++;
      }
    }
  }
}
