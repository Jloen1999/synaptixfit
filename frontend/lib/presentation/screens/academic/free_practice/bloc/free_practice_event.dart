part of 'free_practice_bloc.dart';

@freezed
sealed class FreePracticeEvent with _$FreePracticeEvent {
  const factory FreePracticeEvent.started(String materialId) =
      FreePracticeStarted;

  const factory FreePracticeEvent.answerChanged(String answer) =
      FreePracticeAnswerChanged;

  /// Corrige la respuesta de la pregunta actual.
  const factory FreePracticeEvent.checked() = FreePracticeChecked;

  const factory FreePracticeEvent.nextRequested() = FreePracticeNextRequested;

  /// Cierra la práctica con las respuestas dadas y otorga la XP.
  const factory FreePracticeEvent.finished() = FreePracticeFinished;
}
