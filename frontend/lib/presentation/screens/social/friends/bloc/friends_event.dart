part of 'friends_bloc.dart';

@freezed
sealed class FriendsEvent with _$FriendsEvent {
  /// Carga las cuatro pestañas.
  const factory FriendsEvent.started() = FriendsStarted;

  const factory FriendsEvent.sectionRefreshed(FriendshipListKind kind) =
      FriendsSectionRefreshed;

  const factory FriendsEvent.nextPageRequested(FriendshipListKind kind) =
      FriendsNextPageRequested;

  const factory FriendsEvent.queryChanged(String query) = FriendsQueryChanged;

  const factory FriendsEvent.requestSent(String userId) = FriendsRequestSent;

  const factory FriendsEvent.requestAccepted(String friendshipId) =
      FriendsRequestAccepted;

  const factory FriendsEvent.requestRejected(String friendshipId) =
      FriendsRequestRejected;

  /// Cancela una solicitud, elimina una amistad o desbloquea; [message] es la
  /// confirmación que se muestra.
  const factory FriendsEvent.removed({
    required String friendshipId,
    required SocialMessage message,
  }) = FriendsRemoved;
}
