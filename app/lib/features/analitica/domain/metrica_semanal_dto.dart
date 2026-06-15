// ---------------------------------------------------------------------------
// DTO para datos agregados semanales desde la vista v_analitica_semanal.
// Cada fila representa una semana de entrenamiento para un usuario.
// ---------------------------------------------------------------------------

/// Helpers de parseo locales (duplicados de db_models.dart para no acoplar).
DateTime _parseDateTime(dynamic value, {dynamic fallback}) {
  if (value is DateTime) return value;
  if (value == null) return fallback is DateTime ? fallback : DateTime.now();
  return DateTime.parse(value.toString());
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

double _parseDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value == null) return fallback;
  return double.tryParse(value.toString()) ?? fallback;
}

class MetricaSemanal {
  const MetricaSemanal({
    required this.semanaInicio,
    required this.sesiones,
    required this.rpePromedio,
    required this.minutosTotales,
    required this.caloriasTotales,
  });

  /// Lunes de la semana (inicio del periodo).
  final DateTime semanaInicio;

  /// Cantidad de sesiones completadas en esa semana.
  final int sesiones;

  /// RPE promedio de las sesiones de la semana (escala 1-10).
  final double rpePromedio;

  /// Suma de minutos entrenados en la semana.
  final int minutosTotales;

  /// Suma de calorias quemadas en la semana.
  final int caloriasTotales;

  /// Construye una instancia desde el mapa devuelto por Supabase.
  factory MetricaSemanal.fromMap(Map<String, dynamic> map) {
    return MetricaSemanal(
      semanaInicio: _parseDateTime(map['semana_inicio']),
      sesiones: _parseInt(map['sesiones']),
      rpePromedio: _parseDouble(map['rpe_promedio']),
      minutosTotales: _parseInt(map['minutos_totales']),
      caloriasTotales: _parseInt(map['calorias_totales']),
    );
  }

  /// Serializa a un mapa para graficos y providers.
  Map<String, dynamic> toMap() {
    return {
      'semana_inicio': semanaInicio.toIso8601String(),
      'sesiones': sesiones,
      'rpe_promedio': rpePromedio,
      'minutos_totales': minutosTotales,
      'calorias_totales': caloriasTotales,
    };
  }
}
