part of 'admin_users_bloc.dart';

@freezed
abstract class AdminUsersState with _$AdminUsersState {
  const factory AdminUsersState({
    @Default(AdminStatus.initial) AdminStatus status,
    @Default(AdminUserQuery()) AdminUserQuery query,
    @Default(0) int page,
    AdminPage<AdminUserSummary>? users,
    AppError? error,
  }) = _AdminUsersState;
}
