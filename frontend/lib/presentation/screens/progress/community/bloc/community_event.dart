part of 'community_bloc.dart';

@freezed
sealed class CommunityEvent with _$CommunityEvent {
  /// Primera carga (con esqueleto) y suscripción a los cambios sociales.
  const factory CommunityEvent.started() = CommunityStarted;

  /// Vuelve a leer sin ocultar lo que se ve (deslizar, volver de otra
  /// pantalla, un cambio social en otra parte de la app).
  const factory CommunityEvent.refreshed() = CommunityRefreshed;

  const factory CommunityEvent.requestAccepted(String friendshipId) =
      CommunityRequestAccepted;

  const factory CommunityEvent.requestRejected(String friendshipId) =
      CommunityRequestRejected;
}
