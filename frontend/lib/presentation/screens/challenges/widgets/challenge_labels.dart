import 'package:flutter/material.dart' hide Visibility;
import 'package:intl/intl.dart';

import '../../../../domain/enums/challenge_difficulty.dart';
import '../../../../domain/enums/challenge_link_type.dart';
import '../../../../domain/enums/challenge_status.dart';
import '../../../../domain/enums/challenge_type.dart';
import '../../../../domain/enums/milestone_condition.dart';
import '../../../../domain/enums/milestone_status.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/challenges/challenge.dart';
import '../../../../domain/models/challenges/challenge_draft_validator.dart';
import '../../../extensions/context_extensions.dart';

/// Etiquetas e iconos de los enums de retos (fuente única para todas las pantallas).
extension ChallengeDifficultyLabel on ChallengeDifficulty {
  /// Esfuerzo amigable: Tranquilo / Equilibrado / Intenso.
  String effortLabel(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      ChallengeDifficulty.low => l10n.challengesEffortLow,
      ChallengeDifficulty.medium => l10n.challengesEffortMedium,
      ChallengeDifficulty.high => l10n.challengesEffortHigh,
    };
  }

  IconData get icon => switch (this) {
    ChallengeDifficulty.low => Icons.spa_outlined,
    ChallengeDifficulty.medium => Icons.balance_rounded,
    ChallengeDifficulty.high => Icons.local_fire_department_outlined,
  };
}

extension ChallengeTypeLabel on ChallengeType {
  String label(BuildContext context) => switch (this) {
    ChallengeType.academic => context.localizations.challengesTypeAcademic,
    ChallengeType.fitness => context.localizations.challengesTypeFitness,
  };

  IconData get icon => switch (this) {
    ChallengeType.academic => Icons.school_outlined,
    ChallengeType.fitness => Icons.fitness_center_rounded,
  };

  /// Acento del dominio: estudio = tertiary, entrenamiento = secondary.
  Color color(BuildContext context) => switch (this) {
    ChallengeType.academic => context.colors.tertiary,
    ChallengeType.fitness => context.colors.secondary,
  };
}

extension ChallengeStatusLabel on ChallengeStatus {
  String label(BuildContext context) => switch (this) {
    ChallengeStatus.active => context.localizations.challengesStatusActive,
    ChallengeStatus.completed =>
      context.localizations.challengesStatusCompleted,
    ChallengeStatus.expired => context.localizations.challengesStatusExpired,
  };

  /// Etiqueta en plural para filtros y resumen.
  String pluralLabel(BuildContext context) => switch (this) {
    ChallengeStatus.active => context.localizations.challengesSummaryActive,
    ChallengeStatus.completed =>
      context.localizations.challengesSummaryCompleted,
    ChallengeStatus.expired => context.localizations.challengesSummaryExpired,
  };

  IconData get icon => switch (this) {
    ChallengeStatus.active => Icons.flag_outlined,
    ChallengeStatus.completed => Icons.emoji_events_outlined,
    ChallengeStatus.expired => Icons.timer_off_outlined,
  };

  Color color(BuildContext context) => switch (this) {
    ChallengeStatus.active => context.colors.primary,
    ChallengeStatus.completed => context.palette.success,
    ChallengeStatus.expired => context.palette.warning,
  };
}

extension MilestoneStatusLabel on MilestoneStatus {
  String label(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      MilestoneStatus.locked => l10n.challengesMilestoneLocked,
      MilestoneStatus.available => l10n.challengesMilestoneAvailable,
      MilestoneStatus.inProgress => l10n.challengesMilestoneInProgress,
      MilestoneStatus.completed => l10n.challengesMilestoneCompleted,
    };
  }

  IconData get icon => switch (this) {
    MilestoneStatus.locked => Icons.lock_outline_rounded,
    MilestoneStatus.available => Icons.radio_button_unchecked_rounded,
    MilestoneStatus.inProgress => Icons.timelapse_rounded,
    MilestoneStatus.completed => Icons.check_circle_rounded,
  };

  Color color(BuildContext context) => switch (this) {
    MilestoneStatus.locked => context.colors.onSurfaceVariant,
    MilestoneStatus.available => context.colors.primary,
    MilestoneStatus.inProgress => context.palette.warning,
    MilestoneStatus.completed => context.palette.success,
  };
}

extension MilestoneConditionLabel on MilestoneCondition {
  /// Texto corto de la condición; [n] y [total] solo se usan en «X de Y».
  String label(BuildContext context, {int n = 1, int total = 1}) {
    final l10n = context.localizations;
    return switch (this) {
      MilestoneCondition.all => l10n.challengesConditionAll,
      MilestoneCondition.any => l10n.challengesConditionAny,
      MilestoneCondition.xOfY => l10n.challengesConditionXOfY(n, total),
    };
  }
}

extension ChallengeLinkTypeLabel on ChallengeLinkType {
  String label(BuildContext context) => switch (this) {
    ChallengeLinkType.exam => context.localizations.challengesLinkExamLabel,
    ChallengeLinkType.delivery =>
      context.localizations.challengesLinkDeliveryLabel,
    ChallengeLinkType.block => context.localizations.challengesLinkBlockLabel,
  };

  /// Frase «Vinculado a…» del detalle.
  String linkedLabel(BuildContext context) => switch (this) {
    ChallengeLinkType.exam => context.localizations.challengesLinkExam,
    ChallengeLinkType.delivery => context.localizations.challengesLinkDelivery,
    ChallengeLinkType.block => context.localizations.challengesLinkBlock,
  };

  IconData get icon => switch (this) {
    ChallengeLinkType.exam => Icons.quiz_outlined,
    ChallengeLinkType.delivery => Icons.assignment_outlined,
    ChallengeLinkType.block => Icons.event_note_outlined,
  };
}

extension ChallengeVisibilityLabel on Visibility {
  String challengeLabel(BuildContext context) => switch (this) {
    Visibility.private => context.localizations.challengesVisibilityPrivate,
    Visibility.friends => context.localizations.challengesVisibilityFriends,
    Visibility.public => context.localizations.challengesVisibilityPublic,
  };

  IconData get challengeIcon => switch (this) {
    Visibility.private => Icons.lock_outline_rounded,
    Visibility.friends => Icons.group_outlined,
    Visibility.public => Icons.public_rounded,
  };
}

extension ChallengeDraftIssueText on ChallengeDraftIssue {
  String text(BuildContext context, {double weightSum = 0}) {
    final l10n = context.localizations;
    return switch (this) {
      ChallengeDraftIssue.titleTooShort => l10n.challengesIssueTitle,
      ChallengeDraftIssue.invalidDates => l10n.challengesIssueDates,
      ChallengeDraftIssue.tooManyMilestones => l10n.challengesIssueTooMany,
      ChallengeDraftIssue.milestoneTitleTooShort =>
        l10n.challengesIssueTaskTitle,
      ChallengeDraftIssue.weightsIncomplete =>
        l10n.challengesIssueWeightsIncomplete,
      ChallengeDraftIssue.weightOutOfRange => l10n.challengesIssueWeightRange,
      ChallengeDraftIssue.weightsSum => l10n.challengesIssueWeightsSum(
        ChallengeFormats.number(weightSum),
      ),
      ChallengeDraftIssue.dependencyInvalid => l10n.challengesIssueDependency,
      ChallengeDraftIssue.dependencyCycle => l10n.challengesIssueCycle,
      ChallengeDraftIssue.conditionInvalid => l10n.challengesIssueCondition,
      ChallengeDraftIssue.attachmentConflict => l10n.challengesIssueAttachment,
      ChallengeDraftIssue.sessionTargetInvalid =>
        l10n.challengesIssueSessionTarget,
    };
  }
}

extension ChallengeWeightsLabel on Challenge {
  /// Si cada tarea debe decir cuánto vale: solo con pesos manuales. Se compara
  /// con el reparto automático (que no siempre es exacto, p. ej. 33,33 / 33,34)
  /// con la misma tolerancia que el formulario.
  bool get showsTaskWeights {
    final auto = ChallengeDraftValidator.autoWeights(milestones.length);
    final sorted = [...milestones]..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < sorted.length; i++) {
      if ((sorted[i].weight - auto[i]).abs() > 0.01) return true;
    }
    return false;
  }
}

/// Formatos de fecha y número del módulo (locale `es`).
abstract final class ChallengeFormats {
  static String shortDate(DateTime date) => DateFormat('d MMM').format(date);

  static String longDate(DateTime date) => DateFormat('d MMM y').format(date);

  static String dateTime(DateTime date) =>
      DateFormat('EEE d MMM, HH:mm').format(date);

  /// Número con hasta dos decimales y coma decimal.
  static String number(double value) => NumberFormat('#,##0.##').format(value);

  /// Días naturales que faltan hasta [end] (0 = hoy, negativo = vencido).
  static int daysLeft(DateTime end, DateTime now) {
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(end.year, end.month, end.day);
    return b.difference(a).inDays;
  }
}
