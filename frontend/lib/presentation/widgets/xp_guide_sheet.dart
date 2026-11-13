import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

import '../theme/app_icons.dart';

/// Abre la hoja «Cómo se gana XP»: explica de dónde sale la experiencia y sus
/// topes. Es solo texto: la XP la calcula el servidor (reglas en
/// `docs/01-architecture/formulas.md`, «Progreso justo»); si cambian, se
/// actualizan estos textos. La usan la tarjeta de nivel y la sesión terminada.
Future<void> showXpGuideSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _XpGuideSheet(),
    );

class _XpGuideSheet extends StatelessWidget {
  const _XpGuideSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final palette = context.palette;
    final items = <(IconData, Color, String, String)>[
      (
        Icons.fitness_center_rounded,
        palette.sessions,
        l10n.xpGuideTraining,
        l10n.xpGuideTrainingDetail,
      ),
      (
        Icons.fact_check_outlined,
        palette.sessions,
        l10n.xpGuideCheckIn,
        l10n.xpGuideCheckInDetail,
      ),
      (
        AppIcons.calendar,
        palette.study,
        l10n.xpGuideBlocks,
        l10n.xpGuideBlocksDetail,
      ),
      (
        AppIcons.tabCalendar,
        palette.study,
        l10n.xpGuidePlanning,
        l10n.xpGuidePlanningDetail,
      ),
      (
        AppIcons.focusTimer,
        palette.study,
        l10n.xpGuidePomodoro,
        l10n.xpGuidePomodoroDetail,
      ),
      (
        Icons.school_outlined,
        palette.study,
        l10n.xpGuideStudyWeek,
        l10n.xpGuideStudyWeekDetail,
      ),
      (
        Icons.quiz_outlined,
        palette.study,
        l10n.xpGuideTests,
        l10n.xpGuideTestsDetail,
      ),
      (
        Icons.assignment_turned_in_outlined,
        palette.study,
        l10n.xpGuideDeadlines,
        l10n.xpGuideDeadlinesDetail,
      ),
      (
        Icons.emoji_events_outlined,
        palette.accent,
        l10n.xpGuideChallenges,
        l10n.xpGuideChallengesDetail,
      ),
    ];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 1,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.l,
          0,
          TokensSpacing.l,
          TokensSpacing.l,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.xpGuideTitle,
              style: context.textStyles.titleLarge,
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.xpGuideIntro,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          for (final (icon, color, title, detail) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.m),
              child: MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: TokensSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.textStyles.titleSmall),
                          const SizedBox(height: TokensSpacing.xxs),
                          Text(detail, style: context.textStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text(
            l10n.xpGuideFooter,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
