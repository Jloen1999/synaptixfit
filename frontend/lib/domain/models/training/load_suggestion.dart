import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';

part 'load_suggestion.freezed.dart';

/// Cifra que cambia en una propuesta de carga.
enum LoadMetric {
  weight('WEIGHT'),
  reps('REPS'),
  holdSeconds('HOLD_SECONDS'),
  durationSeconds('DURATION_SECONDS'),
  distanceMeters('DISTANCE_METERS');

  const LoadMetric(this.api);

  final String api;

  static LoadMetric? fromApi(String? value) =>
      values.where((m) => m.api == value).firstOrNull;
}

/// Propuesta de carga de hoy en un ejercicio de la sesión en vivo («Hoy
/// prueba 42 kg (+5 %)»). La calcula el servidor desde la última vez que se
/// hizo; aceptarla solo cambia las series que faltan de hoy.
@freezed
abstract class LoadSuggestion with _$LoadSuggestion {
  const factory LoadSuggestion({
    required String plannedExerciseId,
    required LoadMetric metric,

    /// Lo que se hizo la última vez en esa cifra.
    required double previous,

    /// Lo que se propone hoy.
    required double suggested,

    /// Variación redondeada respecto a [previous] (nula si era 0).
    int? changePercent,
    AdjustmentReason? reason,
    required int lastRpe,
    DateTime? lastSessionAt,

    /// Cifra de cada serie planificada (posición n-1 = serie n), en la unidad
    /// de [metric]; la reparte el servidor (pirámides incluidas).
    @Default(<double>[]) List<double> perSet,
  }) = _LoadSuggestion;

  const LoadSuggestion._();

  /// Cifra propuesta para la serie [set] (desde 1): la de [perSet] o, si no
  /// la trae (serie añadida hoy o servidor anterior), la propuesta común.
  double forSet(int set) =>
      set >= 1 && set <= perSet.length ? perSet[set - 1] : suggested;

  bool get increases => suggested > previous;
}
