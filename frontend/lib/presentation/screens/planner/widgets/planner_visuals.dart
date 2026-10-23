import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/planner_enums.dart';
import '../../../extensions/context_extensions.dart';

/// Color, icono y texto de cada tipo de bloque (nunca solo color: siempre icono).
extension BlockTypeVisuals on BlockType {
  Color color(BuildContext context) => switch (this) {
    BlockType.study => context.palette.study,
    BlockType.sport => context.colors.secondary,
    BlockType.classSession => context.colors.primary,
    BlockType.rest => context.palette.success,
    BlockType.meal => context.palette.calories,
    BlockType.sleep => context.colors.outline,
    BlockType.exam => context.colors.error,
    BlockType.delivery => context.palette.warning,
    BlockType.review => context.colors.tertiary,
  };

  IconData get icon => switch (this) {
    BlockType.study => Icons.menu_book_rounded,
    BlockType.sport => Icons.fitness_center_rounded,
    BlockType.classSession => Icons.school_rounded,
    BlockType.rest => Icons.self_improvement_rounded,
    BlockType.meal => Icons.restaurant_rounded,
    BlockType.sleep => Icons.bedtime_rounded,
    BlockType.exam => Icons.quiz_rounded,
    BlockType.delivery => Icons.assignment_turned_in_rounded,
    BlockType.review => Icons.replay_rounded,
  };

  String label(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      BlockType.study => l10n.plannerTypeStudy,
      BlockType.sport => l10n.plannerTypeSport,
      BlockType.classSession => l10n.plannerTypeClass,
      BlockType.rest => l10n.plannerTypeRest,
      BlockType.meal => l10n.plannerTypeMeal,
      BlockType.sleep => l10n.plannerTypeSleep,
      BlockType.exam => l10n.plannerTypeExam,
      BlockType.delivery => l10n.plannerTypeDelivery,
      BlockType.review => l10n.plannerTypeReview,
    };
  }
}

extension PlannerPriorityVisuals on PlannerPriority {
  String label(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      PlannerPriority.low => l10n.plannerPriorityLow,
      PlannerPriority.medium => l10n.plannerPriorityMedium,
      PlannerPriority.high => l10n.plannerPriorityHigh,
    };
  }
}

extension ClassKindVisuals on ClassKind {
  String label(BuildContext context) => switch (this) {
    ClassKind.theory => context.localizations.plannerClassTheory,
    ClassKind.practice => context.localizations.plannerClassPractice,
  };
}

extension DeadlineTypeVisuals on DeadlineType {
  String label(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      DeadlineType.exam => l10n.plannerDeadlineTypeExam,
      DeadlineType.assignment => l10n.plannerDeadlineTypeAssignment,
      DeadlineType.presentation => l10n.plannerDeadlineTypePresentation,
      DeadlineType.other => l10n.plannerDeadlineTypeOther,
    };
  }

  IconData get icon => switch (this) {
    DeadlineType.exam => Icons.quiz_rounded,
    DeadlineType.assignment => Icons.assignment_rounded,
    DeadlineType.presentation => Icons.co_present_rounded,
    DeadlineType.other => Icons.flag_rounded,
  };
}

extension BalanceStateVisuals on BalanceState {
  String label(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      BalanceState.inactive => l10n.plannerBalanceInactive,
      BalanceState.balanced => l10n.plannerBalanceBalanced,
      BalanceState.studyHeavy => l10n.plannerBalanceStudyHeavy,
      BalanceState.sportHeavy => l10n.plannerBalanceSportHeavy,
    };
  }

  Color color(BuildContext context) => switch (this) {
    BalanceState.inactive => context.colors.onSurfaceVariant,
    BalanceState.balanced => context.palette.success,
    BalanceState.studyHeavy => context.palette.study,
    BalanceState.sportHeavy => context.colors.secondary,
  };

  IconData get icon => switch (this) {
    BalanceState.inactive => Icons.hourglass_empty_rounded,
    BalanceState.balanced => Icons.balance_rounded,
    BalanceState.studyHeavy => Icons.menu_book_rounded,
    BalanceState.sportHeavy => Icons.fitness_center_rounded,
  };
}

/// Formatos de fecha y hora en español del planificador.
abstract final class PlannerFormats {
  static String time(DateTime t) => DateFormat.Hm('es').format(t);

  static String minutes(int minutesOfDay) =>
      '${(minutesOfDay ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutesOfDay % 60).toString().padLeft(2, '0')}';

  /// «lun 14».
  static String dayShort(DateTime d) => DateFormat('EEE d', 'es').format(d);

  /// «lu», «ma»… para los selectores de días.
  static String weekdayInitials(int weekday) {
    // 2024-01-01 fue lunes.
    final d = DateTime(2024, 1, weekday);
    return DateFormat('EEEEE', 'es').format(d).toUpperCase();
  }

  static String weekdayName(int weekday) =>
      DateFormat('EEEE', 'es').format(DateTime(2024, 1, weekday));

  /// «14 oct».
  static String dayMonth(DateTime d) => DateFormat('d MMM', 'es').format(d);

  /// «lunes, 14 de octubre».
  static String longDate(DateTime d) =>
      DateFormat("EEEE, d 'de' MMMM", 'es').format(d);

  /// «14 oct 2026, 10:00».
  static String dateTime(DateTime d) =>
      DateFormat('d MMM y, HH:mm', 'es').format(d);

  /// Horas con un decimal como máximo («2,5»).
  static String hours(double h) => NumberFormat('#0.#', 'es').format(h);
}
