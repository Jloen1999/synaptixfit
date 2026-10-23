/// Tipo de publicación del muro (para la vista previa de la comunidad).
enum CommunityPostKind {
  sessionCompleted,
  challengeCompleted,
  milestoneReached,
  badgeUnlocked,
  routine,
  challenge,
  other;

  static CommunityPostKind fromApi(String? value) => switch (value) {
    'SESSION_COMPLETED' => sessionCompleted,
    'CHALLENGE_COMPLETED' => challengeCompleted,
    'MILESTONE_REACHED' => milestoneReached,
    'BADGE_UNLOCKED' => badgeUnlocked,
    'ROUTINE' => routine,
    'CHALLENGE' => challenge,
    _ => other,
  };
}
