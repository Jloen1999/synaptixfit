import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_adaptation.freezed.dart';

/// Por qué el servidor adapta hoy la sesión.
enum SessionAdaptationReason {
  examSoon('EXAM_SOON'),
  overtraining('OVERTRAINING'),
  highFatigue('HIGH_FATIGUE'),

  /// Seguimiento del ciclo activo y hoy con molestias o poca energía.
  cycleDiscomfort('CYCLE_DISCOMFORT');

  const SessionAdaptationReason(this.api);

  final String api;

  static SessionAdaptationReason? fromApi(String value) =>
      values.where((r) => r.api == value).firstOrNull;
}

/// Cómo se adapta hoy una sesión (regulación cruzada): motivos y series de
/// cada ejercicio planificado. Lo decide el servidor; el cliente solo lo pinta.
@freezed
abstract class SessionAdaptation with _$SessionAdaptation {
  const factory SessionAdaptation({
    @Default(1.0) double volumeFactor,
    @Default(<SessionAdaptationReason>[]) List<SessionAdaptationReason> reasons,

    /// Series de hoy por id de ejercicio planificado.
    @Default(<String, int>{}) Map<String, int> sets,
  }) = _SessionAdaptation;

  const SessionAdaptation._();

  bool get adapted => reasons.isNotEmpty;
}
