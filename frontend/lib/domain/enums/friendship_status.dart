/// Estado persistido de una amistad.
enum FriendshipStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED'),
  blocked('BLOCKED');

  const FriendshipStatus(this.apiValue);

  final String apiValue;

  static FriendshipStatus fromApi(String? value) =>
      FriendshipStatus.values.firstWhere(
        (s) => s.apiValue == value,
        orElse: () => FriendshipStatus.pending,
      );
}
