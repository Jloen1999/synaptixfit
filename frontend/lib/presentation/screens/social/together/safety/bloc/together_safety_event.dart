part of 'together_safety_bloc.dart';

@freezed
sealed class TogetherSafetyEvent with _$TogetherSafetyEvent {
  const factory TogetherSafetyEvent.blockRequested(String userId) =
      TogetherSafetyBlockRequested;

  const factory TogetherSafetyEvent.reportRequested(
    String userId,
    UserReportContext context,
  ) = TogetherSafetyReportRequested;
}
