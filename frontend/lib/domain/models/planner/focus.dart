import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/planner_enums.dart';

part 'focus.freezed.dart';

/// Fase Pomodoro terminada que se registra en el servidor.
@freezed
abstract class FocusSessionRecord with _$FocusSessionRecord {
  const factory FocusSessionRecord({
    required FocusPhase phase,
    required int durationMinutes,
    @Default(1) int cycles,
    @Default(true) bool completed,

    /// Bloque del calendario o asignatura en la que se concentró (opcional).
    String? blockId,
    String? subjectId,
  }) = _FocusSessionRecord;
}

/// Resultado de registrar una fase: la XP concedida y, en [xpStatus], si se
/// premió, si se alcanzó el tope diario o si la fase no daba XP.
@freezed
abstract class FocusSessionResult with _$FocusSessionResult {
  const factory FocusSessionResult({
    @Default(0) int xpAwarded,
    @Default(FocusXpStatus.notEligible) FocusXpStatus xpStatus,
  }) = _FocusSessionResult;
}

/// Totales de fases completadas.
@freezed
abstract class FocusTotals with _$FocusTotals {
  const factory FocusTotals({
    @Default(0) int focusMinutes,
    @Default(0) int breakMinutes,
    @Default(0) int focusCycles,
    @Default(0) int sessions,
  }) = _FocusTotals;
}

/// Totales de un día.
@freezed
abstract class FocusDay with _$FocusDay {
  const factory FocusDay({
    required DateTime date,
    required FocusTotals totals,
  }) = _FocusDay;
}

/// Estadísticas Pomodoro de hoy y de la semana.
@freezed
abstract class FocusStats with _$FocusStats {
  const factory FocusStats({
    required FocusTotals today,
    required FocusTotals week,
    @Default(<FocusDay>[]) List<FocusDay> days,
  }) = _FocusStats;
}

/// Duraciones recomendadas para el Pomodoro de hoy (las decide el servidor a
/// partir del ciclo de atención y la regulación cruzada; Inicio muestra lo mismo).
@freezed
abstract class FocusPlan with _$FocusPlan {
  const factory FocusPlan({
    required int focusMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int cyclesBeforeLongBreak,

    /// El bloque es más corto de lo habitual por la carga física.
    @Default(false) bool limitedByFatigue,

    /// Límites para ajustar el bloque a mano.
    required int minFocusMinutes,
    required int maxFocusMinutes,

    /// Límites para elegir a mano el descanso corto y el largo (ADR 0053).
    required int minShortBreakMinutes,
    required int maxShortBreakMinutes,
    required int minLongBreakMinutes,
    required int maxLongBreakMinutes,
  }) = _FocusPlan;
}

/// Descansos del Pomodoro que eligió la persona la última vez (ADR 0053). Nulo
/// = el recomendado del día ([FocusPlan]), que puede cambiar cada día.
@freezed
abstract class FocusBreakChoice with _$FocusBreakChoice {
  const factory FocusBreakChoice({
    int? shortBreakMinutes,
    int? longBreakMinutes,
  }) = _FocusBreakChoice;

  const FocusBreakChoice._();

  /// Descanso corto que vale hoy: el elegido, dentro de los límites del
  /// [plan]; si no se eligió, el recomendado.
  int shortFor(FocusPlan plan) => (shortBreakMinutes ?? plan.shortBreakMinutes)
      .clamp(plan.minShortBreakMinutes, plan.maxShortBreakMinutes);

  /// Descanso largo que vale hoy (ver [shortFor]).
  int longFor(FocusPlan plan) => (longBreakMinutes ?? plan.longBreakMinutes)
      .clamp(plan.minLongBreakMinutes, plan.maxLongBreakMinutes);
}
