/// Tipo de publicación del muro social.
enum PostType {
  sessionCompleted('SESSION_COMPLETED'),
  challengeCompleted('CHALLENGE_COMPLETED'),
  milestoneReached('MILESTONE_REACHED'),
  badgeUnlocked('BADGE_UNLOCKED'),
  routine('ROUTINE'),
  challenge('CHALLENGE');

  const PostType(this.apiValue);

  final String apiValue;

  static PostType fromApi(String? value) => PostType.values.firstWhere(
    (t) => t.apiValue == value,
    orElse: () => PostType.milestoneReached,
  );
}
