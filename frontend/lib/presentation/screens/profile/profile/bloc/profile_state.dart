part of 'profile_bloc.dart';

enum ProfileStatus { loading, ready, failure }

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(ProfileStatus.loading) ProfileStatus status,
    Account? account,
    ProfileSummary? summary,

    /// Recarga en segundo plano (pull-to-refresh) en curso.
    @Default(false) bool refreshing,

    /// Solicitudes de amistad recibidas sin responder.
    @Default(0) int pendingRequests,

    /// Error de la última carga (con datos previos se muestra como aviso).
    AppError? error,
  }) = _ProfileState;
}
