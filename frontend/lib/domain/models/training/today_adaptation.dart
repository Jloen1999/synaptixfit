import 'package:freezed_annotation/freezed_annotation.dart';

import 'session_adaptation.dart';

part 'today_adaptation.freezed.dart';

/// Lo que más pesa en la fatiga del registro de hoy (para explicarlo).
enum FatigueCause {
  poorSleep('POOR_SLEEP'),
  stress('STRESS'),
  lowEnergy('LOW_ENERGY'),
  soreness('SORENESS');

  const FatigueCause(this.api);

  final String api;

  static FatigueCause? fromApi(String? value) =>
      values.where((c) => c.api == value).firstOrNull;
}

/// Cómo se adapta hoy el entreno y por qué, sin empezar sesión. Lo decide el
/// servidor; la tarjeta del registro rápido solo lo explica.
@freezed
abstract class TodayAdaptation with _$TodayAdaptation {
  const factory TodayAdaptation({
    @Default(1.0) double volumeFactor,
    @Default(<SessionAdaptationReason>[]) List<SessionAdaptationReason> reasons,
    FatigueCause? fatigueCause,
    @Default(false) bool checkInDone,

    /// Respuestas del registro de hoy (1-5), nulas si aún no lo hay: con
    /// ellas, «Cambiar» parte de lo que ya se contestó.
    int? sleepQuality,
    int? energy,
    int? soreness,
  }) = _TodayAdaptation;

  const TodayAdaptation._();

  bool get adapted => reasons.isNotEmpty;

  /// Lo contestado hoy en el registro rápido, si lo hay completo.
  QuickCheckIn? get todayAnswers =>
      sleepQuality != null && energy != null && soreness != null
      ? QuickCheckIn(
          sleepQuality: sleepQuality!,
          energy: energy!,
          soreness: soreness!,
        )
      : null;
}

/// Registro rápido de tres toques (escalas 1-5): cómo dormiste, la energía y
/// las agujetas. El estrés no se pregunta.
@freezed
abstract class QuickCheckIn with _$QuickCheckIn {
  const factory QuickCheckIn({
    required int sleepQuality,
    required int energy,
    required int soreness,
  }) = _QuickCheckIn;
}
