/// Tipo del banner inteligente del inicio (en orden de prioridad del backend).
enum HomeBannerType {
  physicalOverload,
  overdueDeadlines,
  upcomingDeadlines,
  missedBlocks,
  highFatigue,
  lowAdherence,
  lowEnergy,
  attentionDepleted,
  peakDay,
  studyStreak,
  trainingStreak,
  comeback,
  checkInPending,
  balance;

  /// Valor desconocido o ausente: mensaje genérico de equilibrio.
  static HomeBannerType fromApi(String? value) => switch (value) {
    'PHYSICAL_OVERLOAD' => physicalOverload,
    'OVERDUE_DEADLINES' => overdueDeadlines,
    'UPCOMING_DEADLINES' => upcomingDeadlines,
    'MISSED_BLOCKS' => missedBlocks,
    'HIGH_FATIGUE' => highFatigue,
    'LOW_ADHERENCE' => lowAdherence,
    'LOW_ENERGY' => lowEnergy,
    'ATTENTION_DEPLETED' => attentionDepleted,
    'PEAK_DAY' => peakDay,
    'STUDY_STREAK' => studyStreak,
    'TRAINING_STREAK' => trainingStreak,
    'COMEBACK' => comeback,
    'CHECK_IN_PENDING' => checkInPending,
    _ => balance,
  };
}
