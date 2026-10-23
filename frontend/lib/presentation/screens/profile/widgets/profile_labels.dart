import 'package:flutter/material.dart' hide Visibility;

import '../../../../domain/enums/profile/activity_level.dart';
import '../../../../domain/enums/profile/fitness_goal.dart';
import '../../../../domain/enums/profile/notification_category.dart';
import '../../../../domain/enums/profile/notification_mode.dart';
import '../../../../domain/enums/profile/sex.dart';
import '../../../../domain/enums/profile/study_modality.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';

/// Textos e iconos de los enums del módulo profile.
extension SexLabel on Sex {
  String label(AppLocalizations l10n) => switch (this) {
    Sex.male => l10n.profileSexMale,
    Sex.female => l10n.profileSexFemale,
    Sex.nonBinary => l10n.profileSexNonBinary,
    Sex.preferNotToSay => l10n.profileSexPreferNotToSay,
  };
}

extension ActivityLevelLabel on ActivityLevel {
  String label(AppLocalizations l10n) => switch (this) {
    ActivityLevel.sedentary => l10n.profileActivitySedentary,
    ActivityLevel.light => l10n.profileActivityLight,
    ActivityLevel.moderate => l10n.profileActivityModerate,
    ActivityLevel.high => l10n.profileActivityHigh,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    ActivityLevel.sedentary => l10n.profileActivitySedentaryHint,
    ActivityLevel.light => l10n.profileActivityLightHint,
    ActivityLevel.moderate => l10n.profileActivityModerateHint,
    ActivityLevel.high => l10n.profileActivityHighHint,
  };
}

extension FitnessGoalLabel on FitnessGoal {
  String label(AppLocalizations l10n) => switch (this) {
    FitnessGoal.hypertrophy => l10n.profileGoalHypertrophy,
    FitnessGoal.maxStrength => l10n.profileGoalMaxStrength,
    FitnessGoal.power => l10n.profileGoalPower,
    FitnessGoal.strengthEndurance => l10n.profileGoalStrengthEndurance,
    FitnessGoal.mobility => l10n.profileGoalMobility,
    FitnessGoal.stability => l10n.profileGoalStability,
    FitnessGoal.metabolicConditioning => l10n.profileGoalMetabolic,
  };

  IconData get icon => switch (this) {
    FitnessGoal.hypertrophy => Icons.fitness_center_rounded,
    FitnessGoal.maxStrength => Icons.sports_gymnastics_rounded,
    FitnessGoal.power => Icons.bolt_rounded,
    FitnessGoal.strengthEndurance => Icons.repeat_rounded,
    FitnessGoal.mobility => Icons.self_improvement_rounded,
    FitnessGoal.stability => Icons.balance_rounded,
    FitnessGoal.metabolicConditioning => Icons.local_fire_department_rounded,
  };
}

extension StudyModalityLabel on StudyModality {
  String label(AppLocalizations l10n) => switch (this) {
    StudyModality.inPerson => l10n.profileModalityInPerson,
    StudyModality.hybrid => l10n.profileModalityHybrid,
    StudyModality.online => l10n.profileModalityOnline,
  };
}

extension VisibilityLabel on Visibility {
  String label(AppLocalizations l10n) => switch (this) {
    Visibility.public => l10n.profilePrivacyPublic,
    Visibility.friends => l10n.profilePrivacyFriends,
    Visibility.private => l10n.profilePrivacyPrivate,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    Visibility.public => l10n.profilePrivacyPublicHint,
    Visibility.friends => l10n.profilePrivacyFriendsHint,
    Visibility.private => l10n.profilePrivacyPrivateHint,
  };

  IconData get icon => switch (this) {
    Visibility.public => Icons.public_rounded,
    Visibility.friends => Icons.group_rounded,
    Visibility.private => Icons.lock_rounded,
  };
}

extension NotificationCategoryLabel on NotificationCategory {
  String label(AppLocalizations l10n) => switch (this) {
    NotificationCategory.conflict => l10n.profileNotifCategoryConflict,
    NotificationCategory.fatigueAlert => l10n.profileNotifCategoryFatigue,
    NotificationCategory.milestone => l10n.profileNotifCategoryMilestone,
    NotificationCategory.social => l10n.profileNotifCategorySocial,
    NotificationCategory.academic => l10n.profileNotifCategoryAcademic,
  };

  IconData get icon => switch (this) {
    NotificationCategory.conflict => Icons.event_busy_rounded,
    NotificationCategory.fatigueAlert => Icons.battery_alert_rounded,
    NotificationCategory.milestone => Icons.emoji_events_rounded,
    NotificationCategory.social => Icons.people_alt_rounded,
    NotificationCategory.academic => Icons.school_rounded,
  };
}

extension NotificationModeLabel on NotificationMode {
  String label(AppLocalizations l10n) => switch (this) {
    NotificationMode.normal => l10n.profileNotifModeNormal,
    NotificationMode.exams => l10n.profileNotifModeExams,
    NotificationMode.rest => l10n.profileNotifModeRest,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    NotificationMode.normal => l10n.profileNotifModeNormalHint,
    NotificationMode.exams => l10n.profileNotifModeExamsHint,
    NotificationMode.rest => l10n.profileNotifModeRestHint,
  };
}

/// Días de la semana ISO (1 = lunes).
abstract final class ProfileWeekdays {
  static String short(AppLocalizations l10n, int day) => switch (day) {
    1 => l10n.profileWeekdayMon,
    2 => l10n.profileWeekdayTue,
    3 => l10n.profileWeekdayWed,
    4 => l10n.profileWeekdayThu,
    5 => l10n.profileWeekdayFri,
    6 => l10n.profileWeekdaySat,
    _ => l10n.profileWeekdaySun,
  };

  static String long(AppLocalizations l10n, int day) => switch (day) {
    1 => l10n.profileWeekdayMonLong,
    2 => l10n.profileWeekdayTueLong,
    3 => l10n.profileWeekdayWedLong,
    4 => l10n.profileWeekdayThuLong,
    5 => l10n.profileWeekdayFriLong,
    6 => l10n.profileWeekdaySatLong,
    _ => l10n.profileWeekdaySunLong,
  };
}

/// Equipamiento que se ofrece en el perfil físico (valores que guarda la API).
enum ProfileEquipment {
  bodyweight('peso_corporal', Icons.accessibility_new_rounded),
  dumbbell('mancuerna', Icons.fitness_center_rounded),
  barbell('barra', Icons.sports_gymnastics_rounded),
  band('banda_elastica', Icons.cable_rounded),
  kettlebell('kettlebell', Icons.sports_martial_arts_rounded),
  cable('polea', Icons.settings_input_component_rounded),
  machine('maquina', Icons.precision_manufacturing_rounded),
  medicineBall('medicina_ball', Icons.sports_baseball_rounded);

  const ProfileEquipment(this.value, this.icon);

  final String value;
  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
    ProfileEquipment.bodyweight => l10n.profileEquipmentBodyweight,
    ProfileEquipment.dumbbell => l10n.profileEquipmentDumbbell,
    ProfileEquipment.barbell => l10n.profileEquipmentBarbell,
    ProfileEquipment.band => l10n.profileEquipmentBand,
    ProfileEquipment.kettlebell => l10n.profileEquipmentKettlebell,
    ProfileEquipment.cable => l10n.profileEquipmentCable,
    ProfileEquipment.machine => l10n.profileEquipmentMachine,
    ProfileEquipment.medicineBall => l10n.profileEquipmentMedicineBall,
  };

  /// Etiqueta de un valor guardado (los desconocidos se muestran tal cual).
  static String labelOf(AppLocalizations l10n, String value) {
    for (final e in values) {
      if (e.value == value) return e.label(l10n);
    }
    return value;
  }
}
