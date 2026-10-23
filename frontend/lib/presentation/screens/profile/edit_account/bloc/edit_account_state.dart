part of 'edit_account_bloc.dart';

@freezed
sealed class EditAccountState with _$EditAccountState {
  const factory EditAccountState.idle() = EditAccountIdle;

  const factory EditAccountState.submitting() = EditAccountSubmitting;

  const factory EditAccountState.success(Account account) = EditAccountSuccess;

  const factory EditAccountState.failure(AppError error) = EditAccountFailure;
}
