part of 'check_in_bloc.dart';

@freezed
sealed class CheckInEvent with _$CheckInEvent {
  const factory CheckInEvent.started() = CheckInStarted;

  const factory CheckInEvent.inputChanged(CheckInInput input) =
      CheckInInputChanged;

  const factory CheckInEvent.submitted() = CheckInSubmitted;
}
