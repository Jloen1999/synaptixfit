part of 'edit_account_bloc.dart';

@freezed
sealed class EditAccountEvent with _$EditAccountEvent {
  const factory EditAccountEvent.submitted({
    required String fullName,
    required Visibility privacy,
    UsageFocus? usageFocus,
    DateTime? birthDate,
    @Default(false) bool clearBirthDate,
  }) = EditAccountSubmitted;
}
