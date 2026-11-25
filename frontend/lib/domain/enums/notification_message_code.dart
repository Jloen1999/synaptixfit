/// Qué dice un aviso automático (el cliente pone el texto en su idioma). Los
/// avisos sin código, o con uno desconocido, muestran el texto guardado.
enum NotificationMessageCode {
  challengeCompleted('CHALLENGE_COMPLETED'),
  badgeEarned('BADGE_EARNED'),
  levelUp('LEVEL_UP'),
  fatigueCheckIn('FATIGUE_CHECK_IN'),
  overtraining('OVERTRAINING'),
  postLiked('POST_LIKED'),
  postCommented('POST_COMMENTED'),
  friendRequestReceived('FRIEND_REQUEST_RECEIVED'),
  friendRequestAccepted('FRIEND_REQUEST_ACCEPTED'),
  routineCompleted('ROUTINE_COMPLETED'),
  friendChallengeInvited('FRIEND_CHALLENGE_INVITED'),
  friendStreakInvited('FRIEND_STREAK_INVITED'),
  workoutTogetherInvited('WORKOUT_TOGETHER_INVITED'),
  studyRoomInvited('STUDY_ROOM_INVITED'),
  friendStreakNudge('FRIEND_STREAK_NUDGE'),

  /// «Compartir › Con un amigo» (ADR 0064).
  noteReceived('NOTE_RECEIVED');

  const NotificationMessageCode(this.apiValue);

  final String apiValue;

  static NotificationMessageCode? fromApi(String? value) {
    for (final c in values) {
      if (c.apiValue == value) return c;
    }
    return null;
  }
}
