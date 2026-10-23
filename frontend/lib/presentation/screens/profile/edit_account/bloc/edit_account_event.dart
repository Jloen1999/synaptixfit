part of 'edit_account_bloc.dart';

@freezed
sealed class EditAccountEvent with _$EditAccountEvent {
  const factory EditAccountEvent.submitted({
    required String fullName,
    required String avatarUrl,
    required Visibility privacy,
    UsageFocus? usageFocus,
  }) = EditAccountSubmitted;
}
