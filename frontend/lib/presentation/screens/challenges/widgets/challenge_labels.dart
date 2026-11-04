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
import '../../../widgets/app_date_block.dart';
import '../../../widgets/routine_day_labels.dart';

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
    ChallengeStatus.upcoming => context.localizations.challengesStatusUpcoming,
    ChallengeStatus.active => context.localizations.challengesStatusActive,
    ChallengeStatus.completed =>
      context.localizations.challengesStatusCompleted,
    ChallengeStatus.expired => context.localizations.challengesStatusExpired,
  };

  /// Etiqueta en plural para filtros y resumen.
  String pluralLabel(BuildContext context) => switch (this) {
    ChallengeStatus.upcoming => context.localizations.challengesSummaryUpcoming,
    ChallengeStatus.active => context.localizations.challengesSummaryActive,
    ChallengeStatus.completed =>
      context.localizations.challengesSummaryCompleted,
    ChallengeStatus.expired => context.localizations.challengesSummaryExpired,
  };

  IconData get icon => switch (this) {
    ChallengeStatus.upcoming => Icons.schedule_rounded,
    ChallengeStatus.active => Icons.flag_outlined,
    ChallengeStatus.completed => Icons.emoji_events_outlined,
    ChallengeStatus.expired => Icons.timer_off_outlined,
  };

  Color color(BuildContext context) => switch (this) {
    ChallengeStatus.upcoming => context.colors.onSurfaceVariant,
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
    ChallengeLinkType.routineDay =>
      context.localizations.challengesLinkRoutineDayLabel,
  };

  /// Frase «Vinculado a…» del detalle.
  String linkedLabel(BuildContext context) => switch (this) {
    ChallengeLinkType.exam => context.localizations.challengesLinkExam,
    ChallengeLinkType.delivery => context.localizations.challengesLinkDelivery,
    ChallengeLinkType.routineDay =>
      context.localizations.challengesLinkRoutineDay,
  };

  IconData get icon => switch (this) {
    ChallengeLinkType.exam => Icons.quiz_outlined,
    ChallengeLinkType.delivery => Icons.assignment_outlined,
    ChallengeLinkType.routineDay => Icons.fitness_center_rounded,
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
  String text(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      ChallengeDraftIssue.titleTooShort => l10n.challengesIssueTitle,
      ChallengeDraftIssue.invalidDates => l10n.challengesIssueDates,
      ChallengeDraftIssue.tooManyMilestones => l10n.challengesIssueTooMany,
      ChallengeDraftIssue.milestoneTitleTooShort =>
        l10n.challengesIssueTaskTitle,
      ChallengeDraftIssue.dependencyInvalid => l10n.challengesIssueDependency,
      ChallengeDraftIssue.dependencyCycle => l10n.challengesIssueCycle,
      ChallengeDraftIssue.conditionInvalid => l10n.challengesIssueCondition,
      ChallengeDraftIssue.attachmentConflict => l10n.challengesIssueAttachment,
      ChallengeDraftIssue.sessionTargetInvalid =>
        l10n.challengesIssueSessionTarget,
    };
  }
}

/// Cuándo toca un reto, para agruparlo y para el bloque de fecha de su
/// tarjeta: es solo presentación (el estado lo decide el servidor).
enum ChallengeWhen { today, thisWeek, later, upcoming, expired, completed }

/// Días hasta el fin a partir de los que un reto activo se marca como urgente.
const challengeUrgentDays = 1;

extension ChallengeWhenOf on Challenge {
  /// Grupo del reto hoy: los activos por los días que les quedan (hoy, los
  /// próximos 6 días o más adelante); el resto, por su estado.
  ChallengeWhen whenAt(DateTime now) => switch (status) {
    ChallengeStatus.completed => ChallengeWhen.completed,
    ChallengeStatus.expired => ChallengeWhen.expired,
    ChallengeStatus.upcoming => ChallengeWhen.upcoming,
    ChallengeStatus.active => switch (ChallengeFormats.daysLeft(endAt, now)) {
      <= 0 => ChallengeWhen.today,
      <= 6 => ChallengeWhen.thisWeek,
      _ => ChallengeWhen.later,
    },
  };

  /// Frase de cuándo toca, en palabras de cada día: «Vence hoy», «Vence en 3
  /// días», «Empieza el 10 nov», «Venció el 2 nov».
  String whenText(BuildContext context, DateTime now) {
    final l10n = context.localizations;
    switch (status) {
      case ChallengeStatus.completed:
        return l10n.challengesWhenDone;
      case ChallengeStatus.expired:
        return l10n.challengesWhenExpiredOn(ChallengeFormats.shortDate(endAt));
      case ChallengeStatus.upcoming:
        return ChallengeFormats.daysLeft(startAt, now) == 1
            ? l10n.challengesWhenStartsTomorrow
            : l10n.challengesWhenStartsOn(ChallengeFormats.shortDate(startAt));
      case ChallengeStatus.active:
        return challengeDueText(context, endAt, now);
    }
  }

  /// Vence hoy o mañana: se destaca con el color de aviso.
  bool isUrgentAt(DateTime now) =>
      status == ChallengeStatus.active &&
      ChallengeFormats.daysLeft(endAt, now) <= challengeUrgentDays;
}

/// «Vence hoy», «Vence mañana», «Vence en 3 días» o «Vence el lun 3 nov»
/// (la comparten las tarjetas de reto y la lista de tareas pendientes).
String challengeDueText(BuildContext context, DateTime end, DateTime now) {
  final l10n = context.localizations;
  final days = ChallengeFormats.daysLeft(end, now);
  if (days <= 0) return l10n.challengesWhenDueToday;
  if (days == 1) return l10n.challengesWhenDueTomorrow;
  if (days <= 6) return l10n.challengesWhenDueIn(days);
  return l10n.challengesWhenDueOn(ChallengeFormats.weekdayDate(end));
}

extension ChallengeWhenLabel on ChallengeWhen {
  String title(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      ChallengeWhen.today => l10n.challengesGroupToday,
      ChallengeWhen.thisWeek => l10n.challengesGroupThisWeek,
      ChallengeWhen.later => l10n.challengesGroupLater,
      ChallengeWhen.upcoming => l10n.challengesGroupUpcoming,
      ChallengeWhen.expired => l10n.challengesGroupExpired,
      ChallengeWhen.completed => l10n.challengesGroupCompleted,
    };
  }
}

extension MilestoneSourceLabel on Milestone {
  /// Qué la completa si no es un toque: su entrega/examen («Se completa al
  /// hacer “Práctica 2” · 12 dic») o sus bloques del calendario («2/3 bloques
  /// hechos»). `null` si se marca a mano.
  String? sourceText(BuildContext context) {
    if (!completedByLink) return null;
    final l10n = context.localizations;
    if (link == null) {
      return l10n.challengesMilestoneBlocks(
        studyBlocksCompleted,
        studyBlocksTotal,
      );
    }
    final title = linkTitle;
    final due = linkDueAt;
    if (title == null) return l10n.challengesCompletedByDeadlineGeneric;
    // Día de rutina: se dice qué día («Fuerza · semana 2, martes»).
    if (link?.type == ChallengeLinkType.routineDay) {
      return l10n.challengesCompletedByDeadline(
        l10n.challengesLinkRoutineDayTitle(
          title,
          linkWeekNumber ?? 1,
          weekdayName(l10n, linkDayNumber ?? 1),
        ),
      );
    }
    final text = l10n.challengesCompletedByDeadline(title);
    return due == null
        ? text
        : l10n.challengesFeedbackJoin(text, ChallengeFormats.shortDate(due));
  }
}

/// Formatos de fecha y número del módulo (locale `es`).
abstract final class ChallengeFormats {
  static String shortDate(DateTime date) => DateFormat('d MMM').format(date);

  /// «lun 3 nov»: el día de la semana ayuda a situar la fecha de un vistazo.
  static String weekdayDate(DateTime date) =>
      DateFormat('EEE d MMM').format(date);

  static String longDate(DateTime date) => DateFormat('d MMM y').format(date);

  static String dateTime(DateTime date) =>
      DateFormat('EEE d MMM, HH:mm').format(date);

  /// Número con hasta dos decimales y coma decimal.
  static String number(double value) => NumberFormat('#,##0.##').format(value);

  /// Días naturales que faltan hasta [end] (0 = hoy, negativo = vencido).
  static int daysLeft(DateTime end, DateTime now) =>
      AppDueDates.daysUntil(end, now);
}
