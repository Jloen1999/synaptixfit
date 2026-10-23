part of 'admin_user_detail_bloc.dart';

/// Acciones administrativas sobre un usuario.
enum AdminUserAction {
  identity,
  progress,
  role,
  shadowban,
  wipe,
  anonymize,
  delete,
  export,
}

/// Resultado puntual de una acción, para avisos y diálogos.
@freezed
sealed class AdminUserEffect with _$AdminUserEffect {
  const factory AdminUserEffect.saved(AdminUserAction action) =
      AdminUserSavedEffect;

  const factory AdminUserEffect.erased(
    AdminUserAction action,
    ErasureReport report,
  ) = AdminUserErasedEffect;

  const factory AdminUserEffect.exported(String json) = AdminUserExportedEffect;

  const factory AdminUserEffect.failure(AppError error) =
      AdminUserFailureEffect;
}

@freezed
abstract class AdminUserDetailState with _$AdminUserDetailState {
  const factory AdminUserDetailState({
    @Default('') String userId,
    @Default(AdminStatus.initial) AdminStatus status,
    AdminUserDetail? detail,
    AdminUserStats? stats,
    @Default(<AdminWeeklyActivity>[]) List<AdminWeeklyActivity> activity,
    AppError? statsError,
    @Default(<AdminTimelineEntry>[]) List<AdminTimelineEntry> timeline,
    @Default(0) int timelinePage,
    @Default(false) bool timelineHasMore,
    @Default(false) bool timelineLoading,
    AppError? timelineError,

    /// Acción en curso (bloquea el resto de acciones).
    AdminUserAction? busyAction,
    AdminUserEffect? effect,
    AppError? error,
  }) = _AdminUserDetailState;
}
