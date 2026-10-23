part of 'friends_bloc.dart';

/// Estado de la búsqueda de usuarios.
enum UserSearchStatus { idle, loading, loaded, failure }

/// Una pestaña de amistades.
@freezed
abstract class FriendsSection with _$FriendsSection {
  const factory FriendsSection({
    @Default(SocialLoadStatus.loading) SocialLoadStatus status,
    @Default(<Friendship>[]) List<Friendship> items,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,

    /// Recargando sin ocultar la lista (pull-to-refresh).
    @Default(false) bool refreshing,
    AppError? error,
  }) = _FriendsSection;
}

@freezed
abstract class FriendsState with _$FriendsState {
  const factory FriendsState({
    @Default(<FriendshipListKind, FriendsSection>{})
    Map<FriendshipListKind, FriendsSection> sections,
    @Default('') String query,
    @Default(UserSearchStatus.idle) UserSearchStatus searchStatus,
    @Default(<UserCard>[]) List<UserCard> results,
    AppError? searchError,

    /// Amistades o usuarios con una acción en curso.
    @Default(<String>{}) Set<String> busyIds,
    SocialFeedback? feedback,
  }) = _FriendsState;

  const FriendsState._();

  FriendsSection section(FriendshipListKind kind) =>
      sections[kind] ?? const FriendsSection();

  /// Hay una búsqueda activa (se muestran resultados en lugar de pestañas).
  bool get searching => query.length >= FriendsBloc.minQueryLength;
}
