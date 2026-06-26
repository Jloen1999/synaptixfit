import 'package:flutter/foundation.dart';

/// Servicio de cálculo calórico basado en el estándar MET
/// (Metabolic Equivalent of Task) del Compendio de Adultos 2024.
///
/// Fórmula:  (valorMet × pesoUsuarioKg × duracionHoras)
///            = valorMet × pesoUsuarioKg × (duracionSegundos / 3600)
///
/// Si el peso del usuario es nulo o inválido, se usa 70.0 kg por defecto
/// y se registra un warning en consola (sin bloquear la UI).
class CalorieCalculatorService {
  const CalorieCalculatorService._();

  static const _pesoPorDefecto = 70.0;

  /// Calcula las calorías estimadas para un bloque de entrenamiento.
  ///
  /// - [valorMet]: coeficiente MET del ejercicio.
  /// - [pesoUsuarioKg]: peso corporal del usuario en kg (puede ser nulo).
  /// - [duracionSegundos]: duración del bloque en segundos.
  ///
  /// Retorna 0 si la duración es ≤ 0.
  static double calcular({
    required double valorMet,
    double? pesoUsuarioKg,
    required int duracionSegundos,
  }) {
    if (duracionSegundos <= 0) return 0;

    final peso = _sanitizarPeso(pesoUsuarioKg);
    final horas = duracionSegundos / 3600.0;
    return valorMet * peso * horas;
  }

  /// Calcula las calorías para un periodo de descanso (MET = 1.5).
  static double calcularDescanso({
    double? pesoUsuarioKg,
    required int duracionSegundos,
  }) {
    return calcular(
      valorMet: 1.5,
      pesoUsuarioKg: pesoUsuarioKg,
      duracionSegundos: duracionSegundos,
    );
  }

  /// Calcula el gasto calórico total de una lista de bloques de ejercicio,
  /// incluyendo los descansos entre bloques.
  ///
  /// Cada bloque se representa como un mapa con claves:
  ///  - `valorMet` (double)
  ///  - `duracionSegundos` (int)
  ///  - `descansoSegundos` (int)
  static double calcularTotal({
    double? pesoUsuarioKg,
    required List<Map<String, dynamic>> bloques,
  }) {
    double total = 0;
    for (final b in bloques) {
      final met = (b['valorMet'] as num).toDouble();
      final dur = (b['duracionSegundos'] as num).toInt();
      final desc = (b['descansoSegundos'] as num?)?.toInt() ?? 0;

      total += calcular(
        valorMet: met,
        pesoUsuarioKg: pesoUsuarioKg,
        duracionSegundos: dur,
      );

      if (desc > 0) {
        total += calcularDescanso(
          pesoUsuarioKg: pesoUsuarioKg,
          duracionSegundos: desc,
        );
      }
    }
    return total;
  }

  /// Obtiene el valor MET según la clasificación programática del ejercicio.
  ///
  /// Usa el [valorMet] del catálogo si está disponible; en caso contrario
  /// deriva un valor por defecto a partir de la modalidad y el tipo.
  static double derivarMet({
    double? valorMet,
    String modalidad = 'fuerza',
    bool esCircuito = false,
  }) {
    if (valorMet != null && valorMet > 0) return valorMet;

    if (esCircuito) return 8.0;

    return switch (modalidad) {
      'movilidad' => 2.3,
      'metabolica' => 8.0,
      'aerobica' => 8.3,
      _ => 6.0, // fuerza por defecto
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static double _sanitizarPeso(double? pesoUsuarioKg) {
    if (pesoUsuarioKg == null || pesoUsuarioKg <= 0) {
      debugPrint(
        '[CalorieCalculatorService] Peso del usuario no disponible, '
        'usando $_pesoPorDefecto kg por defecto.',
      );
      return _pesoPorDefecto;
    }
    return pesoUsuarioKg;
  }

  /// Redondea las calorías a un entero presentable (sin decimales).
  static int redondear(double calorias) => calorias.round();
}
