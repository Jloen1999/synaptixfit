import 'package:flutter/material.dart' hide Badge;
import 'package:intl/intl.dart';

import '../../../../domain/enums/analytics_enums.dart';
import '../../../../domain/enums/analytics_period.dart';
import '../../../../domain/enums/badge_category.dart';
import '../../../../domain/enums/badge_criterion.dart';
import '../../../../domain/enums/badge_rarity.dart';
import '../../../../domain/enums/community_post_kind.dart';
import '../../../../domain/models/progress/badge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';

/// Formatos numéricos y de fecha del módulo (locale `es`).
abstract final class ProgressFormat {
  static String integer(num value) =>
      NumberFormat.decimalPattern('es').format(value.round());

  /// Un decimal como máximo (`3,5`).
  static String oneDecimal(num value) =>
      NumberFormat('#,##0.#', 'es').format(value);

  /// Dos decimales con signo para coeficientes y pendientes (`-0,42`).
  static String signed(num value, {int decimals = 2}) {
    final formatted = NumberFormat(
      '0.${'0' * decimals}',
      'es',
    ).format(value.abs());
    return value < 0 ? '-$formatted' : formatted;
  }

  static String date(DateTime value) => DateFormat.yMMMd('es').format(value);

  /// Etiqueta corta de semana para los ejes (`12 oct`).
  static String week(DateTime value) => DateFormat('d MMM', 'es').format(value);

  static String relative(DateTime value, DateTime now) {
    final diff = now.difference(value);
    if (diff.inDays >= 7) return DateFormat.MMMd('es').format(value);
    if (diff.inDays >= 1) return DateFormat.E('es').format(value);
    return DateFormat.Hm('es').format(value);
  }
}

extension ProgressLabels on AppLocalizations {
  String badgeCategory(BadgeCategory? category) => switch (category) {
    null => progressBadgeCategoryAll,
    BadgeCategory.training => progressBadgeCategoryTraining,
    BadgeCategory.study => progressBadgeCategoryStudy,
    BadgeCategory.social => progressBadgeCategorySocial,
    BadgeCategory.streak => progressBadgeCategoryStreak,
    BadgeCategory.special => progressBadgeCategorySpecial,
  };

  String badgeRarity(BadgeRarity rarity) => switch (rarity) {
    BadgeRarity.common => progressBadgeRarityCommon,
    BadgeRarity.rare => progressBadgeRarityRare,
    BadgeRarity.epic => progressBadgeRarityEpic,
    BadgeRarity.legendary => progressBadgeRarityLegendary,
  };

  String badgeCriterion(Badge badge) {
    final n = badge.criterionValue;
    return switch (badge.criterion) {
      BadgeCriterion.sessionsCompleted =>
        progressBadgeCriterionSessionsCompleted(n),
      BadgeCriterion.highRpeSessions => progressBadgeCriterionHighRpeSessions(
        n,
      ),
      BadgeCriterion.consecutiveCheckIns =>
        progressBadgeCriterionConsecutiveCheckIns(n),
      BadgeCriterion.studyBlocks => progressBadgeCriterionStudyBlocks(n),
      BadgeCriterion.studyPlans => progressBadgeCriterionStudyPlans(n),
      BadgeCriterion.notesCreated => progressBadgeCriterionNotesCreated(n),
      BadgeCriterion.feedPosts => progressBadgeCriterionFeedPosts(n),
      BadgeCriterion.likesReceived => progressBadgeCriterionLikesReceived(n),
      BadgeCriterion.streakDays => progressBadgeCriterionStreakDays(n),
      BadgeCriterion.challengesCompleted =>
        progressBadgeCriterionChallengesCompleted(n),
      BadgeCriterion.badgesEarned => progressBadgeCriterionBadgesEarned(n),
      BadgeCriterion.planAdherenceWeeks =>
        progressBadgeCriterionPlanAdherenceWeeks(n),
      BadgeCriterion.unknown => progressBadgeCriterionUnknown,
    };
  }

  String analyticsPeriod(AnalyticsPeriod period) => switch (period) {
    AnalyticsPeriod.weekly => progressPeriodWeekly,
    AnalyticsPeriod.monthly => progressPeriodMonthly,
    AnalyticsPeriod.quarterly => progressPeriodQuarterly,
  };

  String trendDirection(TrendDirection direction) => switch (direction) {
    TrendDirection.up => progressRpeDirectionUp,
    TrendDirection.down => progressRpeDirectionDown,
    TrendDirection.stable => progressRpeDirectionStable,
    TrendDirection.insufficientData => progressRpeDirectionInsufficient,
  };

  String correlationMetric(CorrelationMetric metric) => switch (metric) {
    CorrelationMetric.rpe => progressCorrelationMetricRpe,
    CorrelationMetric.minutes => progressCorrelationMetricMinutes,
  };

  /// «Correlación fuerte, negativa» o «Correlación sin relación clara».
  String correlationLabel(
    CorrelationStrength? strength,
    CorrelationDirection? direction,
  ) {
    final s = switch (strength) {
      CorrelationStrength.weak => progressCorrelationStrengthWeak,
      CorrelationStrength.moderate => progressCorrelationStrengthModerate,
      CorrelationStrength.strong => progressCorrelationStrengthStrong,
      CorrelationStrength.veryStrong => progressCorrelationStrengthVeryStrong,
      CorrelationStrength.none || null => progressCorrelationStrengthNone,
    };
    if (strength == null ||
        strength == CorrelationStrength.none ||
        direction == null) {
      return progressCorrelationNoneLabel(s);
    }
    final d = direction == CorrelationDirection.positive
        ? progressCorrelationDirectionPositive
        : progressCorrelationDirectionNegative;
    return progressCorrelationLabel(s, d);
  }

  String postKind(CommunityPostKind kind) => switch (kind) {
    CommunityPostKind.sessionCompleted => progressPostKindSessionCompleted,
    CommunityPostKind.challengeCompleted => progressPostKindChallengeCompleted,
    CommunityPostKind.milestoneReached => progressPostKindMilestoneReached,
    CommunityPostKind.badgeUnlocked => progressPostKindBadgeUnlocked,
    CommunityPostKind.routine => progressPostKindRoutine,
    CommunityPostKind.challenge => progressPostKindChallenge,
    CommunityPostKind.other => progressPostKindOther,
  };
}

/// Colores e iconos por rareza y categoría (siempre acompañados de texto).
extension ProgressColors on BuildContext {
  Color rarityColor(BadgeRarity rarity) => switch (rarity) {
    BadgeRarity.common => colors.onSurfaceVariant,
    BadgeRarity.rare => palette.sessions,
    BadgeRarity.epic => palette.study,
    BadgeRarity.legendary => palette.accent,
  };
}

IconData badgeCategoryIcon(BadgeCategory? category) => switch (category) {
  null => Icons.apps_rounded,
  BadgeCategory.training => Icons.fitness_center_rounded,
  BadgeCategory.study => Icons.school_rounded,
  BadgeCategory.social => Icons.groups_rounded,
  BadgeCategory.streak => Icons.local_fire_department_rounded,
  BadgeCategory.special => Icons.auto_awesome_rounded,
};
