import 'package:flutter/material.dart';

import '../../../../domain/enums/home_banner_type.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../home_external_paths.dart';

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
        icon: Icons.event_busy_outlined,
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
        actionPath: HomeExternalPaths.pomodoro,
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
    // Sin liveRegion: Inicio se refresca en segundo plano con cada cambio de
    // datos y el aviso se volvería a leer sin que el usuario haya hecho nada.
    return Semantics(
      container: true,
      child: AppCard(
        color: Color.alphaBlend(
          accent.withValues(alpha: AppPill.tintAlpha),
          context.colors.surface,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(TokensSpacing.s),
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
                  Text(content.title, style: context.textStyles.titleMedium),
                  const SizedBox(height: TokensSpacing.xs),
                  Text(content.message, style: context.textStyles.bodyMedium),
                  if (path != null && content.actionLabel != null) ...[
                    const SizedBox(height: TokensSpacing.s),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton(
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
