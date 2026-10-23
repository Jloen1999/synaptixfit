part of 'practice_hub_bloc.dart';

@freezed
sealed class PracticeHubEvent with _$PracticeHubEvent {
  const factory PracticeHubEvent.started(String materialId) =
      PracticeHubStarted;

  const factory PracticeHubEvent.refreshed() = PracticeHubRefreshed;

  /// Genera con IA el banco de preguntas (o lo regenera).
  const factory PracticeHubEvent.bankRequested() = PracticeHubBankRequested;
}
