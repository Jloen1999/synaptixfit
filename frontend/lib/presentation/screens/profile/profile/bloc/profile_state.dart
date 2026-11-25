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

    /// Amigos que tienes (para «Aún ninguno» / «3 amigos» de la tarjetita);
    /// nulo si no se ha podido contar.
    int? friendsTotal,

    /// Si esta pantalla pide el recuento de solicitudes: el Perfil sí; las
    /// fichas Físico y Académico no (lo fija `started`, lo sigue `refreshed`).
    @Default(true) bool countsFriendRequests,

    /// Error de la última carga (con datos previos se muestra como aviso).
    AppError? error,
  }) = _ProfileState;
}
