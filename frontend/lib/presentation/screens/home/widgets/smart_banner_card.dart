import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/home_banner_type.dart';
import '../../../../domain/enums/home_event_type.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../home_external_paths.dart';
import 'agenda_section.dart';

/// Texto, icono, tono y acción del banner inteligente según su tipo.
class SmartBannerContent {
  const SmartBannerContent({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
    this.actionLabel,
    this.actionPath,
  });

  final IconData icon;
  final String title;
  final String message;
  final SmartBannerTone tone;
  final String? actionLabel;
  final String? actionPath;

  /// Redacta el banner con las traducciones y sus parámetros.
  factory SmartBannerContent.of(BuildContext context, HomeSmartBanner banner) {
    final l10n = context.localizations;
    int asInt(String key) => banner.param(key).round();
    int asPercent(String key) => (banner.param(key) * 100).round();

    return switch (banner.type) {
      HomeBannerType.physicalOverload => SmartBannerContent(
        icon: Icons.monitor_heart_outlined,
        title: l10n.homeBannerPhysicalOverloadTitle,
        // Sin el ratio: es jerga; quien lo quiera lo ve en la analítica.
        message: l10n.homeBannerPhysicalOverloadMessage(
          asInt('maxStudyMinutes'),
        ),
        tone: SmartBannerTone.warning,
        actionLabel: l10n.homeBannerActionAnalytics,
        actionPath: HomeExternalPaths.analytics,
      ),
      HomeBannerType.overdueDeadlines => SmartBannerContent(
        icon: Icons.assignment_late_outlined,
        title: l10n.homeBannerOverdueDeadlinesTitle(asInt('count')),
        message: l10n.homeBannerOverdueDeadlinesMessage(asInt('count')),
        tone: SmartBannerTone.warning,
        actionLabel: l10n.homeBannerActionDeadlines,
        actionPath: HomeExternalPaths.deadlines,
      ),
      HomeBannerType.missedBlocks => SmartBannerContent(
        icon: Icons.history_rounded,
        title: _missedTitle(context, banner),
        message: l10n.homeBannerMissedBlocksMessage(asInt('count')),
        tone: SmartBannerTone.warning,
        actionLabel: l10n.homeBannerActionReschedule,
        actionPath: HomeExternalPaths.planner,
      ),
      HomeBannerType.upcomingDeadlines => SmartBannerContent(
        icon: Icons.event_note_outlined,
        title: l10n.homeBannerUpcomingDeadlinesTitle(asInt('count')),
        message: l10n.homeBannerUpcomingDeadlinesMessage(
          asInt('daysUntilNext'),
        ),
        tone: SmartBannerTone.warning,
        actionLabel: l10n.homeBannerActionDeadlines,
        actionPath: HomeExternalPaths.deadlines,
      ),
      HomeBannerType.highFatigue => SmartBannerContent(
        icon: Icons.battery_alert_outlined,
        title: l10n.homeBannerHighFatigueTitle,
        message: l10n.homeBannerHighFatigueMessage(asInt('fatigueScore')),
        tone: SmartBannerTone.warning,
      ),
      HomeBannerType.lowAdherence => SmartBannerContent(
        icon: Icons.trending_down_rounded,
        title: l10n.homeBannerLowAdherenceTitle,
        message: l10n.homeBannerLowAdherenceMessage(asInt('adherence')),
        tone: SmartBannerTone.warning,
        actionLabel: l10n.homeBannerActionPlan,
        actionPath: HomeExternalPaths.planner,
      ),
      HomeBannerType.lowEnergy => SmartBannerContent(
        icon: Icons.battery_2_bar_rounded,
        title: l10n.homeBannerLowEnergyTitle,
        message: l10n.homeBannerLowEnergyMessage(asInt('energy')),
        tone: SmartBannerTone.warning,
      ),
      HomeBannerType.attentionDepleted => SmartBannerContent(
        icon: Icons.psychology_alt_outlined,
        title: l10n.homeBannerAttentionDepletedTitle,
        message: l10n.homeBannerAttentionDepletedMessage(
          asPercent('attentionCapacity'),
        ),
        tone: SmartBannerTone.warning,
        actionLabel: l10n.homeBannerActionPomodoro,
        actionPath: HomeExternalPaths.pomodoroBreak,
      ),
      HomeBannerType.peakDay => SmartBannerContent(
        icon: Icons.bolt_rounded,
        title: l10n.homeBannerPeakDayTitle,
        message: l10n.homeBannerPeakDayMessage(asInt('energy')),
        tone: SmartBannerTone.positive,
        actionLabel: l10n.homeBannerActionTrain,
        actionPath: HomeExternalPaths.training,
      ),
      HomeBannerType.studyStreak => SmartBannerContent(
        icon: Icons.auto_stories_outlined,
        title: l10n.homeBannerStudyStreakTitle(asInt('days')),
        message: l10n.homeBannerStudyStreakMessage,
        tone: SmartBannerTone.positive,
      ),
      HomeBannerType.trainingStreak => SmartBannerContent(
        icon: Icons.local_fire_department_outlined,
        title: l10n.homeBannerTrainingStreakTitle(asInt('days')),
        message: l10n.homeBannerTrainingStreakMessage,
        tone: SmartBannerTone.positive,
      ),
      HomeBannerType.comeback => SmartBannerContent(
        icon: Icons.waving_hand_outlined,
        title: l10n.homeBannerComebackTitle,
        message: l10n.homeBannerComebackMessage(
          asInt('daysInactive'),
          asPercent('loadFactor'),
        ),
        tone: SmartBannerTone.positive,
        actionLabel: l10n.homeBannerActionTrain,
        actionPath: HomeExternalPaths.training,
      ),
      HomeBannerType.checkInPending => SmartBannerContent(
        icon: Icons.fact_check_outlined,
        title: l10n.homeBannerCheckInPendingTitle,
        message: l10n.homeBannerCheckInPendingMessage,
        tone: SmartBannerTone.neutral,
        actionLabel: l10n.homeBannerActionCheckIn,
        actionPath: HomeExternalPaths.checkIn,
      ),
      HomeBannerType.balance => SmartBannerContent(
        icon: Icons.balance_rounded,
        title: l10n.homeBannerBalanceTitle,
        message: l10n.homeBannerBalanceMessage,
        tone: SmartBannerTone.neutral,
      ),
    };
  }
}

/// «Álgebra (hoy a las 16:00) se quedó sin hacer»: el bloque más reciente
/// por su nombre (o su tipo) y su hora, para saber cuál es sin abrir nada.
String _missedTitle(BuildContext context, HomeSmartBanner banner) {
  final l10n = context.localizations;
  final count = banner.param('count').round();
  final activity = banner.labels['activity'];
  if (activity == null) return l10n.homeBannerMissedBlocksTitle(count);
  final name =
      banner.labels['title'] ??
      eventTypeLabel(context, HomeEventType.fromApi(activity));
  final minutes = banner.param('startMinutes').round();
  final time = DateFormat.Hm().format(
    DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60),
  );
  final when = banner.param('yesterday') == 1
      ? l10n.homeBannerWhenYesterday(time)
      : l10n.homeBannerWhenToday(time);
  return count <= 1
      ? l10n.homeBannerMissedBlockOne(name, when)
      : l10n.homeBannerMissedBlockMany(name, when, count - 1);
}

enum SmartBannerTone { warning, positive, neutral }

/// Banner inteligente del día con acción contextual opcional.
class SmartBannerCard extends StatelessWidget {
  const SmartBannerCard({
    super.key,
    required this.banner,
    required this.onAction,
  });

  final HomeSmartBanner banner;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final content = SmartBannerContent.of(context, banner);
    final accent = switch (content.tone) {
      SmartBannerTone.warning => context.palette.warning,
      SmartBannerTone.positive => context.palette.success,
      SmartBannerTone.neutral => context.colors.primary,
    };
    final path = content.actionPath;
    // En móvil ocupa la mitad: lo urgente se lee y el próximo entreno sigue a
    // la vista sin desplazar.
    final compact =
        MediaQuery.sizeOf(context).width < TokensLayout.twoColumnBreakpoint;
    // Sin liveRegion: Inicio se refresca en segundo plano con cada cambio de
    // datos y el aviso se volvería a leer sin que el usuario haya hecho nada.
    return Semantics(
      container: true,
      child: AppCard(
        padding: EdgeInsets.all(compact ? TokensSpacing.sm : TokensSpacing.m),
        color: Color.alphaBlend(
          accent.withValues(alpha: AppPill.tintAlpha),
          context.colors.surface,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(
                compact ? TokensSpacing.xs : TokensSpacing.s,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: AppPill.tintAlpha),
                borderRadius: BorderRadius.circular(TokensRadius.m),
              ),
              child: Icon(content.icon, color: accent),
            ),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: compact
                        ? context.textStyles.titleSmall
                        : context.textStyles.titleMedium,
                  ),
                  const SizedBox(height: TokensSpacing.xxs),
                  Text(content.message, style: context.textStyles.bodyMedium),
                  if (path != null && content.actionLabel != null) ...[
                    SizedBox(
                      height: compact ? TokensSpacing.xxs : TokensSpacing.s,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: compact
                          ? TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TokensSpacing.xs,
                                ),
                                foregroundColor: context.colors.onSurface,
                              ),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: TokensSize.iconXs,
                              ),
                              onPressed: () => onAction(path),
                              label: Text(
                                content.actionLabel!,
                                style: context.textStyles.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : FilledButton(
                              onPressed: () => onAction(path),
                              child: Text(content.actionLabel!),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
