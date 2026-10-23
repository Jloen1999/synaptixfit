import 'package:flutter/material.dart';

import '../../../../domain/enums/admin/admin_audit_action.dart';
import '../../../../domain/enums/admin/admin_audit_entity.dart';
import '../../../../domain/enums/admin/admin_erasure_mode.dart';
import '../../../../domain/enums/admin/admin_exercise_difficulty.dart';
import '../../../../domain/enums/admin/admin_exercise_modality.dart';
import '../../../../domain/enums/admin/admin_exercise_purpose.dart';
import '../../../../domain/enums/admin/admin_measurement_type.dart';
import '../../../../domain/enums/admin/admin_report_type.dart';
import '../../../../domain/enums/admin/admin_timeline_type.dart';
import '../../../../domain/enums/admin/admin_user_sort.dart';
import '../../../../domain/enums/admin/admin_user_status.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';

/// Textos e iconos de los enums del módulo admin.
extension UserRoleAdminLabel on UserRole {
  String adminLabel(AppLocalizations l10n) => switch (this) {
    UserRole.user => l10n.adminRoleUser,
    UserRole.admin => l10n.adminRoleAdmin,
  };
}

extension AdminUserStatusLabel on AdminUserStatus {
  String label(AppLocalizations l10n) => switch (this) {
    AdminUserStatus.active => l10n.adminStatusActive,
    AdminUserStatus.deleted => l10n.adminStatusDeleted,
    AdminUserStatus.all => l10n.adminStatusAll,
  };
}

extension AdminUserSortLabel on AdminUserSort {
  String label(AppLocalizations l10n) => switch (this) {
    AdminUserSort.createdAt => l10n.adminSortCreatedAt,
    AdminUserSort.level => l10n.adminSortLevel,
    AdminUserSort.xp => l10n.adminSortXp,
    AdminUserSort.fullName => l10n.adminSortName,
    AdminUserSort.streak => l10n.adminSortStreak,
  };
}

extension AdminReportTypeLabel on AdminReportType {
  String label(AppLocalizations l10n) => switch (this) {
    AdminReportType.post => l10n.adminReportTypePost,
    AdminReportType.comment => l10n.adminReportTypeComment,
  };

  IconData get icon => switch (this) {
    AdminReportType.post => Icons.article_outlined,
    AdminReportType.comment => Icons.chat_bubble_outline_rounded,
  };
}

extension AdminErasureModeLabel on AdminErasureMode {
  String label(AppLocalizations l10n) => switch (this) {
    AdminErasureMode.contentWiped => l10n.adminErasureModeWiped,
    AdminErasureMode.anonymized => l10n.adminErasureModeAnonymized,
    AdminErasureMode.deleted => l10n.adminErasureModeDeleted,
  };
}

extension AdminTimelineTypeLabel on AdminTimelineType {
  String label(AppLocalizations l10n) => switch (this) {
    AdminTimelineType.accountCreated => l10n.adminTimelineAccountCreated,
    AdminTimelineType.trainingSession => l10n.adminTimelineTrainingSession,
    AdminTimelineType.routineCreated => l10n.adminTimelineRoutineCreated,
    AdminTimelineType.challengeCreated => l10n.adminTimelineChallengeCreated,
    AdminTimelineType.challengeCompleted =>
      l10n.adminTimelineChallengeCompleted,
    AdminTimelineType.badgeEarned => l10n.adminTimelineBadgeEarned,
    AdminTimelineType.studyBlockCompleted =>
      l10n.adminTimelineStudyBlockCompleted,
    AdminTimelineType.deadlineCompleted => l10n.adminTimelineDeadlineCompleted,
    AdminTimelineType.noteCreated => l10n.adminTimelineNoteCreated,
    AdminTimelineType.focusSession => l10n.adminTimelineFocusSession,
    AdminTimelineType.postPublished => l10n.adminTimelinePostPublished,
    AdminTimelineType.commentPosted => l10n.adminTimelineCommentPosted,
    AdminTimelineType.adminAction => l10n.adminTimelineAdminAction,
  };

  IconData get icon => switch (this) {
    AdminTimelineType.accountCreated => Icons.person_add_alt_1_outlined,
    AdminTimelineType.trainingSession => Icons.fitness_center_rounded,
    AdminTimelineType.routineCreated => Icons.list_alt_rounded,
    AdminTimelineType.challengeCreated => Icons.flag_outlined,
    AdminTimelineType.challengeCompleted => Icons.flag_rounded,
    AdminTimelineType.badgeEarned => Icons.military_tech_outlined,
    AdminTimelineType.studyBlockCompleted => Icons.school_outlined,
    AdminTimelineType.deadlineCompleted => Icons.event_available_outlined,
    AdminTimelineType.noteCreated => Icons.sticky_note_2_outlined,
    AdminTimelineType.focusSession => Icons.timer_outlined,
    AdminTimelineType.postPublished => Icons.article_outlined,
    AdminTimelineType.commentPosted => Icons.chat_bubble_outline_rounded,
    AdminTimelineType.adminAction => Icons.admin_panel_settings_outlined,
  };

  /// Color de acento según el dominio del evento.
  Color color(ColorScheme colors) => switch (this) {
    AdminTimelineType.trainingSession ||
    AdminTimelineType.routineCreated => colors.secondary,
    AdminTimelineType.studyBlockCompleted ||
    AdminTimelineType.deadlineCompleted ||
    AdminTimelineType.noteCreated ||
    AdminTimelineType.focusSession => colors.tertiary,
    AdminTimelineType.adminAction => colors.error,
    _ => colors.primary,
  };
}

extension AdminAuditEntityLabel on AdminAuditEntity {
  String label(AppLocalizations l10n) => switch (this) {
    AdminAuditEntity.user => l10n.adminAuditEntityUser,
    AdminAuditEntity.platformSettings => l10n.adminAuditEntitySettings,
    AdminAuditEntity.exercise => l10n.adminAuditEntityExercise,
    AdminAuditEntity.socialPost => l10n.adminAuditEntityPost,
    AdminAuditEntity.comment => l10n.adminAuditEntityComment,
    AdminAuditEntity.other => l10n.adminAuditEntityOther,
  };
}

extension AdminAuditActionLabel on AdminAuditAction {
  String label(AppLocalizations l10n) => switch (this) {
    AdminAuditAction.updateName => l10n.adminAuditActionUpdateName,
    AdminAuditAction.updateEmail => l10n.adminAuditActionUpdateEmail,
    AdminAuditAction.setProgress => l10n.adminAuditActionSetProgress,
    AdminAuditAction.resetXp => l10n.adminAuditActionResetXp,
    AdminAuditAction.changeLevel => l10n.adminAuditActionChangeLevel,
    AdminAuditAction.changeRole => l10n.adminAuditActionChangeRole,
    AdminAuditAction.activateShadowban =>
      l10n.adminAuditActionActivateShadowban,
    AdminAuditAction.deactivateShadowban =>
      l10n.adminAuditActionDeactivateShadowban,
    AdminAuditAction.wipeUserData => l10n.adminAuditActionWipeUserData,
    AdminAuditAction.anonymizeUser => l10n.adminAuditActionAnonymizeUser,
    AdminAuditAction.deleteUser => l10n.adminAuditActionDeleteUser,
    AdminAuditAction.exportUserData => l10n.adminAuditActionExportUserData,
    AdminAuditAction.selfDeleteAccount =>
      l10n.adminAuditActionSelfDeleteAccount,
    AdminAuditAction.activateLockdown => l10n.adminAuditActionActivateLockdown,
    AdminAuditAction.deactivateLockdown =>
      l10n.adminAuditActionDeactivateLockdown,
    AdminAuditAction.updateGlobalSettings =>
      l10n.adminAuditActionUpdateGlobalSettings,
    AdminAuditAction.approveContent => l10n.adminAuditActionApproveContent,
    AdminAuditAction.deleteContent => l10n.adminAuditActionDeleteContent,
    AdminAuditAction.createExercise => l10n.adminAuditActionCreateExercise,
    AdminAuditAction.editExercise => l10n.adminAuditActionEditExercise,
    AdminAuditAction.activateExercise => l10n.adminAuditActionActivateExercise,
    AdminAuditAction.deactivateExercise =>
      l10n.adminAuditActionDeactivateExercise,
    AdminAuditAction.deleteExercise => l10n.adminAuditActionDeleteExercise,
    AdminAuditAction.other => l10n.adminAuditActionOther,
  };

  /// Las acciones destructivas se marcan con el color de error.
  bool get isDestructive => switch (this) {
    AdminAuditAction.wipeUserData ||
    AdminAuditAction.anonymizeUser ||
    AdminAuditAction.deleteUser ||
    AdminAuditAction.selfDeleteAccount ||
    AdminAuditAction.deleteContent ||
    AdminAuditAction.deleteExercise ||
    AdminAuditAction.activateShadowban ||
    AdminAuditAction.activateLockdown => true,
    _ => false,
  };
}

extension AdminExerciseDifficultyLabel on AdminExerciseDifficulty {
  String label(AppLocalizations l10n) => switch (this) {
    AdminExerciseDifficulty.beginner => l10n.adminDifficultyBeginner,
    AdminExerciseDifficulty.intermediate => l10n.adminDifficultyIntermediate,
    AdminExerciseDifficulty.advanced => l10n.adminDifficultyAdvanced,
  };
}

extension AdminExerciseModalityLabel on AdminExerciseModality {
  String label(AppLocalizations l10n) => switch (this) {
    AdminExerciseModality.strength => l10n.adminModalityStrength,
    AdminExerciseModality.mobility => l10n.adminModalityMobility,
    AdminExerciseModality.metabolic => l10n.adminModalityMetabolic,
    AdminExerciseModality.aerobic => l10n.adminModalityAerobic,
  };
}

extension AdminExercisePurposeLabel on AdminExercisePurpose {
  String label(AppLocalizations l10n) => switch (this) {
    AdminExercisePurpose.hypertrophy => l10n.adminPurposeHypertrophy,
    AdminExercisePurpose.maxStrength => l10n.adminPurposeMaxStrength,
    AdminExercisePurpose.power => l10n.adminPurposePower,
    AdminExercisePurpose.strengthEndurance =>
      l10n.adminPurposeStrengthEndurance,
    AdminExercisePurpose.mobility => l10n.adminPurposeMobility,
    AdminExercisePurpose.stability => l10n.adminPurposeStability,
    AdminExercisePurpose.metabolicConditioning =>
      l10n.adminPurposeMetabolicConditioning,
  };
}

extension AdminMeasurementTypeLabel on AdminMeasurementType {
  String label(AppLocalizations l10n) => switch (this) {
    AdminMeasurementType.repetitions => l10n.adminMeasurementRepetitions,
    AdminMeasurementType.weight => l10n.adminMeasurementWeight,
    AdminMeasurementType.time => l10n.adminMeasurementTime,
    AdminMeasurementType.distance => l10n.adminMeasurementDistance,
    AdminMeasurementType.calories => l10n.adminMeasurementCalories,
  };
}
