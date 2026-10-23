part of 'admin_users_bloc.dart';

@freezed
sealed class AdminUsersEvent with _$AdminUsersEvent {
  const factory AdminUsersEvent.started() = AdminUsersStarted;

  /// Recarga la página actual (p. ej. al volver del detalle).
  const factory AdminUsersEvent.refreshed() = AdminUsersRefreshed;

  /// Nuevos filtros, orden o texto de búsqueda: vuelve a la primera página.
  const factory AdminUsersEvent.queryChanged(AdminUserQuery query) =
      AdminUsersQueryChanged;

  const factory AdminUsersEvent.pageRequested(int page) =
      AdminUsersPageRequested;
}
