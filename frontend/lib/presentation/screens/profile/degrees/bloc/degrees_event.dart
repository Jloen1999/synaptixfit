part of 'degrees_bloc.dart';

@freezed
sealed class DegreesEvent with _$DegreesEvent {
  const factory DegreesEvent.started() = DegreesStarted;

  const factory DegreesEvent.linkRequested(Degree degree) =
      DegreesLinkRequested;

  const factory DegreesEvent.unlinkRequested(String degreeId) =
      DegreesUnlinkRequested;
}
