/// Métrica que hay que alcanzar para obtener una insignia.
enum BadgeCriterion {
  sessionsCompleted,
  highRpeSessions,
  consecutiveCheckIns,
  studyBlocks,
  studyPlans,
  notesCreated,
  feedPosts,
  likesReceived,
  streakDays,
  challengesCompleted,
  badgesEarned,
  planAdherenceWeeks,
  unknown;

  static BadgeCriterion fromApi(String? value) => switch (value) {
    'SESSIONS_COMPLETED' => sessionsCompleted,
    'HIGH_RPE_SESSIONS' => highRpeSessions,
    'CONSECUTIVE_CHECK_INS' => consecutiveCheckIns,
    'STUDY_BLOCKS' => studyBlocks,
    'STUDY_PLANS' => studyPlans,
    'NOTES_CREATED' => notesCreated,
    'FEED_POSTS' => feedPosts,
    'LIKES_RECEIVED' => likesReceived,
    'STREAK_DAYS' => streakDays,
    'CHALLENGES_COMPLETED' => challengesCompleted,
    'BADGES_EARNED' => badgesEarned,
    'PLAN_ADHERENCE_WEEKS' => planAdherenceWeeks,
    _ => unknown,
  };
}
