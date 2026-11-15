part of 'challenge_templates_bloc.dart';

@freezed
sealed class ChallengeTemplatesEvent with _$ChallengeTemplatesEvent {
  const factory ChallengeTemplatesEvent.started() = ChallengeTemplatesStarted;

  /// «Empezar este reto».
  const factory ChallengeTemplatesEvent.startRequested(String templateId) =
      ChallengeTemplatesStartRequested;
}
