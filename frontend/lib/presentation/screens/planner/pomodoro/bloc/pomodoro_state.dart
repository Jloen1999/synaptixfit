part of 'pomodoro_bloc.dart';

enum PomodoroStatus { idle, running, paused }

@freezed
abstract class PomodoroState with _$PomodoroState {
  const factory PomodoroState({
    @Default(FocusPhase.focus) FocusPhase phase,
    @Default(PomodoroStatus.idle) PomodoroStatus status,
    required int totalSeconds,
    required int remainingSeconds,

    /// Fases de concentración completadas en esta tanda (para el descanso largo).
    @Default(0) int completedFocusCycles,
    FocusStats? stats,
    @Default(false) bool statsLoading,
    AppError? statsError,
    PomodoroNotice? notice,
    @Default(0) int noticeId,

    /// Recomendación del servidor para hoy (nula hasta que llega).
    FocusPlan? plan,

    /// Asignatura y bloque a los que se vinculan las fases registradas.
    String? subjectId,
    String? blockId,
  }) = _PomodoroState;

  const PomodoroState._();

  /// Se puede cambiar la duración: concentración sin empezar.
  bool get canAdjust =>
      status == PomodoroStatus.idle &&
      phase == FocusPhase.focus &&
      remainingSeconds == totalSeconds;

  /// Fracción restante (1 = fase entera por delante).
  double get remainingFraction =>
      totalSeconds == 0 ? 0 : remainingSeconds / totalSeconds;
}

@freezed
sealed class PomodoroNotice with _$PomodoroNotice {
  /// Ha terminado [finished]; la siguiente fase es [next]. [completed] es
  /// falso si se saltó: entonces no se felicita ni se avisa.
  const factory PomodoroNotice.phaseFinished({
    required FocusPhase finished,
    required FocusPhase next,
    @Default(true) bool completed,
  }) = PomodoroNoticePhaseFinished;

  /// La fase registrada dio [xp]; [account] trae el nivel actualizado.
  const factory PomodoroNotice.xpEarned({required int xp, Account? account}) =
      PomodoroNoticeXpEarned;

  /// Concentración válida sin XP: ya se alcanzó el tope diario del Pomodoro.
  const factory PomodoroNotice.dailyXpLimitReached() =
      PomodoroNoticeDailyXpLimitReached;

  /// No se pudo registrar la fase en el servidor.
  const factory PomodoroNotice.recordFailed(AppError error) =
      PomodoroNoticeRecordFailed;
}
