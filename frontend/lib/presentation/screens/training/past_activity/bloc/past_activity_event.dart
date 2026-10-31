part of 'past_activity_bloc.dart';

@freezed
sealed class PastActivityEvent with _$PastActivityEvent {
  const factory PastActivityEvent.submitted({
    required DateTime start,
    required int minutes,
    required int effort,
    String? title,
  }) = PastActivitySubmitted;
}
