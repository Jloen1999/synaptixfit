import 'package:freezed_annotation/freezed_annotation.dart';

part 'cycle.freezed.dart';

/// Momento estimado del ciclo (lo estima el servidor; ADR 0033).
enum CyclePhase {
  period('PERIOD'),
  afterPeriod('AFTER_PERIOD'),
  midCycle('MID_CYCLE'),
  beforePeriod('BEFORE_PERIOD');

  const CyclePhase(this.api);

  final String api;

  static CyclePhase? fromApi(String? value) =>
      values.where((p) => p.api == value).firstOrNull;
}

/// Energía de un día del ciclo.
enum CycleEnergy {
  low('LOW'),
  normal('NORMAL'),
  high('HIGH');

  const CycleEnergy(this.api);

  final String api;

  static CycleEnergy? fromApi(String? value) =>
      values.where((e) => e.api == value).firstOrNull;
}

/// Molestias que se pueden apuntar un día del ciclo.
enum CycleSymptom {
  abdominalPain('ABDOMINAL_PAIN'),
  lowerBackPain('LOWER_BACK_PAIN'),
  cramps('CRAMPS'),
  bloating('BLOATING'),
  headache('HEADACHE');

  const CycleSymptom(this.api);

  final String api;

  static CycleSymptom? fromApi(String value) =>
      values.where((s) => s.api == value).firstOrNull;
}

/// Lo apuntado un día del seguimiento del ciclo (opcional y privado).
@freezed
abstract class CycleDay with _$CycleDay {
  const factory CycleDay({
    required DateTime date,
    @Default(false) bool period,
    CycleEnergy? energy,
    @Default(<CycleSymptom>{}) Set<CycleSymptom> symptoms,
    String? note,
  }) = _CycleDay;
}

/// Resumen del seguimiento del ciclo: si está activo y, si se puede estimar,
/// el momento del ciclo, el día y desde cuándo se espera la próxima regla.
@freezed
abstract class CycleOverview with _$CycleOverview {
  const factory CycleOverview({
    @Default(false) bool enabled,
    DateTime? consentedAt,
    CyclePhase? phase,
    int? dayOfCycle,
    @Default(28) int cycleLength,
    DateTime? nextPeriodFrom,
    CycleDay? today,
  }) = _CycleOverview;
}
