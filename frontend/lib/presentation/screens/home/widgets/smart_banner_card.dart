import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/home_banner_type.dart';
import '../../../../domain/enums/home_event_type.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../dashboard/bloc/home_dashboard_bloc.dart';
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
        icon: AppIcons.history,
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
      // El entreno de hoy ya viene adaptado a la fatiga: verlo es lo útil.
      HomeBannerType.highFatigue => SmartBannerContent(
        icon: Icons.battery_alert_outlined,
        title: l10n.homeBannerHighFatigueTitle,
        message: l10n.homeBannerHighFatigueMessage(asInt('fatigueScore')),
        tone: SmartBannerTone.warning,
        actionLabel: l10n.homeBannerActionTrainingToday,
        actionPath: HomeExternalPaths.training,
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
        actionLabel: l10n.homeBannerActionTrainingToday,
        actionPath: HomeExternalPaths.training,
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

bool _isSport(HomeSmartBanner banner) =>
    HomeEventType.fromApi(banner.labels['activity']) == HomeEventType.sport;

/// Aviso de un bloque concreto sin hacer, con sus dos acciones: cada una es su
/// propio botón (la tarjeta no es pulsable entera).
class _MissedBlockBanner extends StatelessWidget {
  const _MissedBlockBanner({
    required this.banner,
    required this.blockId,
    required this.busy,
    required this.sport,
    required this.onReschedule,
    required this.onComplete,
  });

  final HomeSmartBanner banner;
  final String blockId;
  final HomeBannerAction? busy;

  /// Un bloque de deporte se marca en el calendario (allí se indica el
  /// esfuerzo): el botón lo dice en vez de «Hecho».
  final bool sport;
  final VoidCallback onReschedule;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final accent = context.palette.warning;
    final count = banner.param('count').round();
    return Semantics(
      container: true,
      child: AppCard(
        padding: const EdgeInsets.all(TokensSpacing.sm),
        color: Color.alphaBlend(
          accent.withValues(alpha: AppPill.tintAlpha),
          context.colors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(TokensSpacing.xs),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: AppPill.tintAlpha),
                    borderRadius: BorderRadius.circular(TokensRadius.m),
                  ),
                  child: Icon(AppIcons.history, color: accent),
                ),
                const SizedBox(width: TokensSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _missedTitle(context, banner),
                        style: context.textStyles.titleSmall,
                      ),
                      Text(
                        l10n.homeBannerMissedBlocksMessage(count),
                        style: context.textStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensSpacing.s),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.s,
              children: [
                AppSecondaryButton(
                  label: l10n.homeBannerActionNextSlot,
                  icon: const Icon(Icons.update_rounded),
                  loading: busy == HomeBannerAction.reschedule,
                  onPressed: busy == null ? onReschedule : null,
                ),
                AppSecondaryButton(
                  label: sport
                      ? l10n.homeBannerActionMarkInCalendar
                      : l10n.homeBannerActionDone,
                  icon: Icon(sport ? AppIcons.calendar : Icons.check_rounded),
                  loading: busy == HomeBannerAction.complete,
                  onPressed: busy == null ? onComplete : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Calendario abierto en el bloque del aviso: su semana es la de hoy o la de
/// ayer, según diga el servidor (`yesterday`).
String _plannerAtBlock(HomeSmartBanner banner, String blockId, DateTime now) {
  final yesterday = banner.param('yesterday') == 1;
  return HomeExternalPaths.plannerAt(
    yesterday ? DateTime(now.year, now.month, now.day - 1) : now,
    blockId: blockId,
  );
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

/// Banner inteligente del día con acción contextual opcional. El de bloques sin
/// hacer, si el servidor dice cuál es (`blockId`), actúa sobre él sin salir:
/// «Al próximo hueco» y «Hecho» (un bloque de deporte se marca en el
/// calendario, donde se indica el esfuerzo).
class SmartBannerCard extends StatelessWidget {
  const SmartBannerCard({
    super.key,
    required this.banner,
    required this.onAction,
    this.onRescheduleBlock,
    this.onCompleteBlock,
    this.busy,
    this.now,
  });

  final HomeSmartBanner banner;
  final ValueChanged<String> onAction;
  final ValueChanged<String>? onRescheduleBlock;
  final ValueChanged<String>? onCompleteBlock;

  /// Acción del bloque que se está aplicando (nula si ninguna).
  final HomeBannerAction? busy;

  /// Momento de referencia (inyectable en tests).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final blockId = banner.type == HomeBannerType.missedBlocks
        ? banner.labels['blockId']
        : null;
    if (blockId != null &&
        onRescheduleBlock != null &&
        onCompleteBlock != null) {
      return _MissedBlockBanner(
        banner: banner,
        blockId: blockId,
        busy: busy,
        onReschedule: () => onRescheduleBlock!(blockId),
        sport: _isSport(banner),
        onComplete: _isSport(banner)
            ? () => onAction(
                _plannerAtBlock(banner, blockId, now ?? DateTime.now()),
              )
            : () => onCompleteBlock!(blockId),
      );
    }
    final content = SmartBannerContent.of(context, banner);
    final accent = switch (content.tone) {
      SmartBannerTone.warning => context.palette.warning,
      SmartBannerTone.positive => context.palette.success,
      SmartBannerTone.neutral => context.colors.primary,
    };
    final path = content.actionPath;
    // En móvil, una sola fila (icono, título y enlace): lo urgente se ve y la
    // agenda sigue a la vista. El detalle lo lee el lector de pantalla y se ve
    // en escritorio, donde sobra espacio.
    final compact =
        MediaQuery.sizeOf(context).width < TokensLayout.twoColumnBreakpoint;
    final action = path != null && content.actionLabel != null
        ? TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.xs),
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
        : null;
    final icon = Container(
      padding: const EdgeInsets.all(TokensSpacing.xs),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: AppPill.tintAlpha),
        borderRadius: BorderRadius.circular(TokensRadius.m),
      ),
      child: Icon(content.icon, color: accent),
    );
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
        // En compacto la tarjeta entera lleva a la acción (el título conserva
        // todo el ancho); sin acción, se ve también el consejo.
        onTap: compact && path != null && content.actionLabel != null
            ? () => onAction(path)
            : null,
        child: compact
            ? Row(
                children: [
                  icon,
                  const SizedBox(width: TokensSpacing.sm),
                  Expanded(
                    child: Semantics(
                      label: '${content.title}. ${content.message}',
                      hint: content.actionLabel,
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.title,
                            style: context.textStyles.titleSmall,
                          ),
                          if (action == null)
                            Text(
                              content.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (action != null) const Icon(AppIcons.next),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: TokensSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.title,
                          style: context.textStyles.titleMedium,
                        ),
                        const SizedBox(height: TokensSpacing.xxs),
                        Text(
                          content.message,
                          style: context.textStyles.bodyMedium,
                        ),
                        if (action != null) ...[
                          const SizedBox(height: TokensSpacing.xs),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: action,
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
