/// DTO para un ejercicio recomendado dentro de una rutina generada
/// por la IA o por las reglas deterministas.
class EjercicioRecomendado {
  const EjercicioRecomendado({
    required this.ejercicioId,
    this.series = 3,
    this.repeticiones = 10,
    this.segundosDescanso = 90,
    this.pesoKg,
    this.duracionObjetivoSegundos,
    this.distanciaMetros,
    this.tiempoIsometricoSegundos,
  });

  final String ejercicioId;
  final int series;
  final int repeticiones;
  final int segundosDescanso;
  final double? pesoKg;
  final int? duracionObjetivoSegundos;
  final int? distanciaMetros;
  final int? tiempoIsometricoSegundos;

  factory EjercicioRecomendado.fromMap(Map<String, dynamic> map) {
    return EjercicioRecomendado(
      ejercicioId: map['exerciseId'] as String? ?? '',
      series: (map['series'] as num?)?.toInt() ?? 3,
      repeticiones: (map['repeticiones'] as num?)?.toInt() ?? 10,
      segundosDescanso: (map['segundosDescanso'] as num?)?.toInt() ?? 90,
      pesoKg: (map['pesoKg'] as num?)?.toDouble(),
      duracionObjetivoSegundos:
          (map['duracionObjetivoSegundos'] as num?)?.toInt(),
      distanciaMetros: (map['distanciaMetros'] as num?)?.toInt(),
      tiempoIsometricoSegundos:
          (map['tiempoIsometricoSegundos'] as num?)?.toInt(),
    );
  }
}

/// Datos resumidos de sesiones previas de un ejercicio individual,
/// usados para que la IA pueda aplicar sobrecarga progresiva.
class EjercicioRecienteDto {
  const EjercicioRecienteDto({
    required this.nombreEjercicio,
    required this.pesoPromedio,
    required this.repsPromedio,
    required this.rpePromedio,
    required this.ultimaFecha,
  });

  final String nombreEjercicio;
  final double pesoPromedio;
  final int repsPromedio;
  final double rpePromedio;
  final DateTime ultimaFecha;
}
