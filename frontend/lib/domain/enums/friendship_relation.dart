/// Relación del usuario autenticado con otro usuario.
enum FriendshipRelation {
  none('NONE'),
  requestSent('REQUEST_SENT'),
  requestReceived('REQUEST_RECEIVED'),
  friends('FRIENDS'),
  blocked('BLOCKED');

  const FriendshipRelation(this.apiValue);

  final String apiValue;

  static FriendshipRelation fromApi(String? value) =>
      FriendshipRelation.values.firstWhere(
        (r) => r.apiValue == value,
        orElse: () => FriendshipRelation.none,
      );
}
