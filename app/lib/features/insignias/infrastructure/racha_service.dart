import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/insignia_dto.dart';

/// Servicio de cálculo de rachas diarias (entrenamiento + estudio).
class RachaService {
  final SupabaseClient _client;

  const RachaService(this._client);

  /// Hitos de racha predefinidos.
  static const _hitos = [7, 30, 100];

  /// Calcula el estado actual de la racha del usuario.
  Future<RachaState> calcularRacha(String usuarioId) async {
    try {
      // 1. Obtener todas las fechas con actividad (sesiones + check-ins)
      final fechasActividad = await _obtenerFechasActividad(usuarioId);

      // 2. Contar días consecutivos hacia atrás desde hoy
      final diasConsecutivos = _calcularDiasConsecutivos(fechasActividad);

      // 3. Verificar si hoy ya tiene actividad
      final hoy = DateTime.now();
      final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);
      final hoyTieneActividad = fechasActividad.contains(hoyFecha);

      // 4. Determinar riesgo (menos de 4h restantes sin actividad hoy)
      final enRiesgo =
          !hoyTieneActividad && hoy.hour >= 20 && diasConsecutivos > 0;

      // 5. Calcular próximo hito y progreso
      int? proximoHito;
      int diasParaProximoHito = 0;
      double progresoHito = 0.0;

      for (final hito in _hitos) {
        if (diasConsecutivos < hito) {
          proximoHito = hito;
          diasParaProximoHito = hito - diasConsecutivos;
          // Progreso desde el hito anterior (o 0)
          final hitoAnterior = _hitos
              .where((h) => h < hito)
              .fold<int>(0, (prev, h) => h > prev ? h : prev);
          final rango = hito - hitoAnterior;
          final progresoEnRango = diasConsecutivos - hitoAnterior;
          progresoHito =
              rango > 0 ? (progresoEnRango / rango).clamp(0.0, 1.0) : 0.0;
          break;
        }
      }

      // Si ya superó todos los hitos, el próximo es el último + siguiente lógica
      if (proximoHito == null && diasConsecutivos >= 100) {
        // Después de 100, el siguiente es 365
        proximoHito = 365;
        diasParaProximoHito = 365 - diasConsecutivos;
        progresoHito = ((diasConsecutivos - 100) / (365 - 100)).clamp(0.0, 1.0);
      }

      // 6. Mejor racha histórica (del campo racha_actual en usuarios)
      final mejorRacha = await _obtenerMejorRacha(usuarioId);

      return RachaState(
        diasConsecutivos: diasConsecutivos,
        mejorRacha: mejorRacha,
        enRiesgo: enRiesgo,
        proximoHito: proximoHito,
        diasParaProximoHito: diasParaProximoHito,
        progresoHito: progresoHito,
      );
    } catch (e) {
      debugPrint('[RachaService] Error calculando racha: $e');
      return const RachaState(diasConsecutivos: 0, mejorRacha: 0);
    }
  }

  /// Obtiene todas las fechas con actividad del usuario.
  Future<Set<DateTime>> _obtenerFechasActividad(String usuarioId) async {
    final fechas = <DateTime>{};

    // Sesiones de entrenamiento
    final sesiones = await _client
        .from('sesiones_registradas')
        .select('completada_en')
        .eq('usuario_id', usuarioId);

    for (final row in (sesiones as List)) {
      final f = (row as Map<String, dynamic>)['completada_en'];
      if (f != null) {
        final dt = DateTime.tryParse(f.toString());
        if (dt != null) fechas.add(DateTime(dt.year, dt.month, dt.day));
      }
    }

    // Check-ins diarios (estado_diario_usuario)
    final checkins = await _client
        .from('estado_diario_usuario')
        .select('fecha')
        .eq('usuario_id', usuarioId);

    for (final row in (checkins as List)) {
      final f = (row as Map<String, dynamic>)['fecha'];
      if (f != null) {
        final dt = DateTime.tryParse(f.toString());
        if (dt != null) fechas.add(DateTime(dt.year, dt.month, dt.day));
      }
    }

    return fechas;
  }

  /// Cuenta días consecutivos hacia atrás desde hoy.
  static int _calcularDiasConsecutivos(Set<DateTime> fechas) {
    if (fechas.isEmpty) return 0;

    final sorted = fechas.toList()..sort((a, b) => b.compareTo(a));
    final hoy = DateTime.now();
    final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final ayer = hoyFecha.subtract(const Duration(days: 1));

    // La fecha más reciente debe ser hoy o ayer
    if (sorted.first != hoyFecha && sorted.first != ayer) {
      return 0;
    }

    int consecutivos = 0;
    DateTime? expected = hoyFecha;

    for (final fecha in sorted) {
      if (fecha == expected) {
        consecutivos++;
        expected = expected!.subtract(const Duration(days: 1));
      } else if (fecha == expected!.add(const Duration(days: 1))) {
        // Salto sobre un día ya contado — continuar
        continue;
      } else {
        break;
      }
    }

    return consecutivos;
  }

  /// Obtiene la mejor racha histórica del usuario.
  Future<int> _obtenerMejorRacha(String usuarioId) async {
    try {
      final data = await _client
          .from('usuarios')
          .select('racha_actual')
          .eq('id', usuarioId)
          .maybeSingle();

      if (data != null) {
        return (data['racha_actual'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Verifica si hoy el usuario ya tiene actividad registrada.
  Future<bool> hoyTieneActividad(String usuarioId) async {
    final fechas = await _obtenerFechasActividad(usuarioId);
    final hoy = DateTime.now();
    final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);
    return fechas.contains(hoyFecha);
  }
}
