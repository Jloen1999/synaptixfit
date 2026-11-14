import 'package:flutter/material.dart';

import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/account/account.dart';
import '../../../../domain/models/progress/streak.dart';
import '../../../../domain/models/progress/study_week.dart';
import '../../../../domain/models/progress/weekly_analytics.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Cabecera de Progreso › Resumen: el titular de la semana («4 h de estudio ·
/// 3 entrenos»), el nivel con su barra y la racha. Lo demás va plegado debajo
/// (vocabulario §4: al grano). Las cifras salen tal cual del servidor.
class WeekHeadlineCard extends StatelessWidget {
  const WeekHeadlineCard({
    super.key,
    required this.account,
    required this.streak,
    required this.focus,
    this.studyWeek,
    this.weekly,
    this.onRetry,
    this.onStart,
  });

  final Account account;
  final Streak streak;
  final UsageFocus focus;

  /// Nulo si no se pudo cargar: el titular lo dice y ofrece reintentar.
  final StudyWeek? studyWeek;

  /// Nulo si no se pudo cargar: el titular lo dice y ofrece reintentar.
  final WeeklyAnalytics? weekly;

  /// «Reintentar» cuando falta una de las cifras del titular.
  final VoidCallback? onRetry;

  /// Acción siguiente con la semana a cero («Añadir al calendario»).
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final study = studyWeek;
    final trainings = weekly?.currentWeek?.sessions;
    // Un fallo de carga no es «no hay datos»: se dice y se puede reintentar.
    final failed =
        (focus.includesAcademic && study == null) ||
        (focus.includesFitness && weekly == null);
    final hours = focus.includesAcademic ? study?.studyHours : null;
    final count = focus.includesFitness ? trainings : null;
    final parts = [
      if (hours != null) l10n.progressHeadlineStudy(hours),
      if (count != null) l10n.progressHeadlineTrainings(count),
    ];
    final empty = !failed && (hours ?? 0) == 0 && (count ?? 0) == 0;
    final headline = empty || parts.isEmpty
        ? l10n.progressHeadlineEmpty
        : parts.join(' · ');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            label: '${l10n.progressHeadlineTitle}: $headline',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.progressHeadlineTitle,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                Text(headline, style: context.textStyles.headlineSmall),
              ],
            ),
          ),
          if (failed && onRetry != null) ...[
            const SizedBox(height: TokensSpacing.s),
            AppInlineMessage(
              message: l10n.progressSectionUnavailable,
              tone: AppMessageTone.warning,
            ),
            const SizedBox(height: TokensSpacing.s),
            AppSecondaryButton(
              label: l10n.commonRetry,
              icon: const Icon(AppIcons.refresh),
              onPressed: onRetry,
            ),
          ] else if (empty && onStart != null) ...[
            const SizedBox(height: TokensSpacing.s),
            AppSecondaryButton(
              label: l10n.progressHeadlineStart,
              icon: const Icon(AppIcons.add),
              onPressed: onStart,
            ),
          ],
          const SizedBox(height: TokensSpacing.m),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: XpProgressBar(
                  level: account.level,
                  levelXp: account.levelXp,
                  levelThreshold: account.levelThreshold,
                ),
              ),
              IconButton(
                tooltip: l10n.xpGuideOpen,
                onPressed: () => showXpGuideSheet(context),
                icon: Icon(
                  AppIcons.help,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          _StreakLine(streak: streak),
        ],
      ),
    );
  }
}

/// «Racha: 5 días · récord 36 días» (sin récord si es 0 o la racha actual) y,
/// si hoy se pierde, una línea que lo dice.
class _StreakLine extends StatelessWidget {
  const _StreakLine({required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final muted = context.colors.onSurfaceVariant;
    final best = streak.bestDays;
    final text = best == 0 || best <= streak.currentDays
        ? l10n.progressHeadlineStreakOnly(streak.currentDays)
        : l10n.progressHeadlineStreak(streak.currentDays, best);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.local_fire_department_rounded,
                color: context.palette.streak,
              ),
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(child: Text(text, style: context.textStyles.bodyMedium)),
          ],
        ),
        if (streak.atRisk)
          Padding(
            padding: const EdgeInsets.only(top: TokensSpacing.xs),
            child: Text(
              l10n.progressStreakAtRisk,
              style: context.textStyles.bodySmall?.copyWith(color: muted),
            ),
          ),
      ],
    );
  }
}
