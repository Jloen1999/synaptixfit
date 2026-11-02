import 'package:flutter/material.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/enums/visibility.dart' as vis;
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../widgets/routine_day_labels.dart';

export '../../../widgets/routine_day_labels.dart';

/// Textos y iconos de los enums del módulo de entrenamiento.

extension TrainingGoalLabel on TrainingGoal {
  String label(AppLocalizations l10n) => switch (this) {
    TrainingGoal.hypertrophy => l10n.trainingGoalHypertrophy,
    TrainingGoal.maxStrength => l10n.trainingGoalMaxStrength,
    TrainingGoal.power => l10n.trainingGoalPower,
    TrainingGoal.strengthEndurance => l10n.trainingGoalStrengthEndurance,
    TrainingGoal.mobility => l10n.trainingGoalMobility,
    TrainingGoal.stability => l10n.trainingGoalStability,
    TrainingGoal.metabolicConditioning => l10n.trainingGoalMetabolic,
  };

  /// Qué significa el objetivo, en una línea y sin jerga.
  String description(AppLocalizations l10n) => switch (this) {
    TrainingGoal.hypertrophy => l10n.trainingGoalHypertrophyHint,
    TrainingGoal.maxStrength => l10n.trainingGoalMaxStrengthHint,
    TrainingGoal.power => l10n.trainingGoalPowerHint,
    TrainingGoal.strengthEndurance => l10n.trainingGoalStrengthEnduranceHint,
    TrainingGoal.mobility => l10n.trainingGoalMobilityHint,
    TrainingGoal.stability => l10n.trainingGoalStabilityHint,
    TrainingGoal.metabolicConditioning => l10n.trainingGoalMetabolicHint,
  };
}

extension ModalityLabel on Modality {
  String label(AppLocalizations l10n) => switch (this) {
    Modality.strength => l10n.trainingModalityStrength,
    Modality.mobility => l10n.trainingModalityMobility,
    Modality.metabolic => l10n.trainingModalityMetabolic,
    Modality.aerobic => l10n.trainingModalityAerobic,
  };

  IconData get icon => switch (this) {
    Modality.strength => Icons.fitness_center_rounded,
    Modality.mobility => Icons.self_improvement_rounded,
    Modality.metabolic => Icons.local_fire_department_rounded,
    Modality.aerobic => Icons.directions_run_rounded,
  };
}

extension ExerciseCategoryLabel on ExerciseCategory {
  String label(AppLocalizations l10n) => switch (this) {
    ExerciseCategory.strength => l10n.trainingCategoryStrength,
    ExerciseCategory.calisthenics => l10n.trainingCategoryCalisthenics,
    ExerciseCategory.stretching => l10n.trainingCategoryStretching,
    ExerciseCategory.mobility => l10n.trainingCategoryMobility,
    ExerciseCategory.cardio => l10n.trainingCategoryCardio,
    ExerciseCategory.plyometrics => l10n.trainingCategoryPlyometrics,
    ExerciseCategory.yoga => l10n.trainingCategoryYoga,
    ExerciseCategory.pilates => l10n.trainingCategoryPilates,
    ExerciseCategory.isometric => l10n.trainingCategoryIsometric,
    ExerciseCategory.olympic => l10n.trainingCategoryOlympic,
    ExerciseCategory.combat => l10n.trainingCategoryCombat,
    ExerciseCategory.rehab => l10n.trainingCategoryRehab,
  };

  IconData get icon => switch (this) {
    ExerciseCategory.strength => Icons.fitness_center_rounded,
    ExerciseCategory.calisthenics => Icons.sports_gymnastics_rounded,
    ExerciseCategory.stretching => Icons.self_improvement_rounded,
    ExerciseCategory.mobility => Icons.threesixty_rounded,
    ExerciseCategory.cardio => Icons.directions_run_rounded,
    ExerciseCategory.plyometrics => Icons.bolt_rounded,
    ExerciseCategory.yoga => Icons.spa_rounded,
    ExerciseCategory.pilates => Icons.waves_rounded,
    ExerciseCategory.isometric => Icons.pause_circle_outline_rounded,
    ExerciseCategory.olympic => Icons.emoji_events_rounded,
    ExerciseCategory.combat => Icons.sports_martial_arts_rounded,
    ExerciseCategory.rehab => Icons.healing_rounded,
  };
}

extension ExerciseDifficultyLabel on ExerciseDifficulty {
  String label(AppLocalizations l10n) => switch (this) {
    ExerciseDifficulty.beginner => l10n.trainingDifficultyBeginner,
    ExerciseDifficulty.intermediate => l10n.trainingDifficultyIntermediate,
    ExerciseDifficulty.advanced => l10n.trainingDifficultyAdvanced,
  };
}

extension RoutineStatusLabel on RoutineStatus {
  String label(AppLocalizations l10n) => switch (this) {
    RoutineStatus.active => l10n.trainingStatusActive,
    RoutineStatus.paused => l10n.trainingStatusPaused,
    RoutineStatus.completed => l10n.trainingStatusCompleted,
    RoutineStatus.archived => l10n.trainingStatusArchived,
  };

  IconData get icon => switch (this) {
    RoutineStatus.active => Icons.play_circle_outline_rounded,
    RoutineStatus.paused => Icons.pause_circle_outline_rounded,
    RoutineStatus.completed => Icons.check_circle_outline_rounded,
    RoutineStatus.archived => Icons.inventory_2_outlined,
  };
}

extension WeekTypeLabel on WeekType {
  String label(AppLocalizations l10n) => switch (this) {
    WeekType.adaptation => l10n.trainingWeekTypeAdaptation,
    WeekType.load => l10n.trainingWeekTypeLoad,
    WeekType.peak => l10n.trainingWeekTypePeak,
    WeekType.deload => l10n.trainingWeekTypeDeload,
  };

  /// Para qué sirve ese tipo de semana, en una línea y sin jerga.
  String description(AppLocalizations l10n) => switch (this) {
    WeekType.adaptation => l10n.trainingWeekTypeAdaptationHint,
    WeekType.load => l10n.trainingWeekTypeLoadHint,
    WeekType.peak => l10n.trainingWeekTypePeakHint,
    WeekType.deload => l10n.trainingWeekTypeDeloadHint,
  };
}

extension ProgressStatusLabel on ProgressStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ProgressStatus.pending => l10n.trainingProgressPending,
    ProgressStatus.inProgress => l10n.trainingProgressInProgress,
    ProgressStatus.completed => l10n.trainingProgressCompleted,
    ProgressStatus.skipped => l10n.trainingProgressSkipped,
  };

  IconData get icon => switch (this) {
    ProgressStatus.pending => Icons.radio_button_unchecked_rounded,
    ProgressStatus.inProgress => Icons.timelapse_rounded,
    ProgressStatus.completed => Icons.check_circle_rounded,
    ProgressStatus.skipped => Icons.redo_rounded,
  };

  /// Hecho o saltado: ya no se propone como próximo.
  bool get isClosed =>
      this == ProgressStatus.completed || this == ProgressStatus.skipped;
}

extension RecommendationTypeLabel on RecommendationType {
  String label(AppLocalizations l10n) => switch (this) {
    RecommendationType.progression => l10n.trainingRecommendationProgression,
    RecommendationType.degradation => l10n.trainingRecommendationDegradation,
    RecommendationType.deload => l10n.trainingRecommendationDeload,
    RecommendationType.variant => l10n.trainingRecommendationVariant,
    RecommendationType.academic => l10n.trainingRecommendationAcademic,
  };

  IconData get icon => switch (this) {
    RecommendationType.progression => Icons.trending_up_rounded,
    RecommendationType.degradation => Icons.trending_down_rounded,
    RecommendationType.deload => Icons.battery_charging_full_rounded,
    RecommendationType.variant => Icons.swap_horiz_rounded,
    RecommendationType.academic => Icons.school_rounded,
  };
}

extension PlanIntensityLabel on PlanIntensity {
  String label(AppLocalizations l10n) => switch (this) {
    PlanIntensity.low => l10n.trainingIntensityLow,
    PlanIntensity.moderate => l10n.trainingIntensityModerate,
    PlanIntensity.high => l10n.trainingIntensityHigh,
  };
}

extension PlanStatusLabel on PlanStatus {
  String label(AppLocalizations l10n) => switch (this) {
    PlanStatus.active => l10n.trainingPlanStatusActive,
    PlanStatus.paused => l10n.trainingPlanStatusPaused,
    PlanStatus.completed => l10n.trainingPlanStatusCompleted,
    PlanStatus.adjusted => l10n.trainingPlanStatusAdjusted,
  };
}

extension VisibilityLabel on vis.Visibility {
  String label(AppLocalizations l10n) => switch (this) {
    vis.Visibility.private => l10n.trainingVisibilityPrivate,
    vis.Visibility.friends => l10n.trainingVisibilityFriends,
    vis.Visibility.public => l10n.trainingVisibilityPublic,
  };

  IconData get icon => switch (this) {
    vis.Visibility.private => Icons.lock_outline_rounded,
    vis.Visibility.friends => Icons.group_outlined,
    vis.Visibility.public => Icons.public_rounded,
  };
}

/// Nombre visible de un día: el propio o el del día de la semana.
String dayTitle(AppLocalizations l10n, int dayNumber, String? name) {
  final trimmed = name?.trim();
  return trimmed == null || trimmed.isEmpty
      ? weekdayName(l10n, dayNumber)
      : trimmed;
}

/// Nombre visible de una semana: el propio o «Semana N».
String weekTitle(AppLocalizations l10n, int number, String? name) {
  final trimmed = name?.trim();
  return trimmed == null || trimmed.isEmpty
      ? l10n.trainingWeekNumber(number)
      : trimmed;
}

/// Duración como `m:ss` o `h:mm:ss`.
String formatClock(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = s ~/ 3600;
  final minutes = (s % 3600) ~/ 60;
  final seconds = (s % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$seconds'
      : '$minutes:$seconds';
}

/// [formatClock] para el lector de pantalla: «0:48» se leería como una hora,
/// así que se dice «48 segundos», «12 minutos y 5 segundos» o «1 hora y 3
/// minutos».
String spokenClock(AppLocalizations l10n, int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = s ~/ 3600;
  final minutes = (s % 3600) ~/ 60;
  final seconds = s % 60;
  if (hours > 0) return l10n.trainingDurationSpokenHourMin(hours, minutes);
  if (minutes > 0) return l10n.trainingDurationSpokenMinSec(minutes, seconds);
  return l10n.trainingDurationSpokenSec(seconds);
}

/// Número decimal sin ceros sobrantes (`20`, `22.5`).
String formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
