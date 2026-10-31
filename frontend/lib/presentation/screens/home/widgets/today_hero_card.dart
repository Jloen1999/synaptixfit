import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/home_event_kind.dart';
import '../../../../domain/enums/home_event_type.dart';
import '../../../../domain/enums/item_time_status.dart';
import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'agenda_section.dart';

/// Qué hace la persona al pulsar el botón principal de «Tu día».
enum TodayHeroAction { focus, train, openPlanner }

/// «Tu día», lo primero de Inicio: cuánto llevas de hoy (anillo con los bloques
/// hechos), qué toca ahora o a continuación con su botón directo, y tres cifras
/// (estudio, entreno y nivel). Responde de un vistazo a «¿qué hago ahora?».
class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({
    super.key,
    required this.dashboard,
    required this.focus,
    required this.onAction,
    this.starting = false,
  });

  final HomeDashboard dashboard;
  final UsageFocus focus;
  final ValueChanged<TodayHeroAction> onAction;

  /// Se está abriendo la sesión de entrenamiento.
  final bool starting;

  /// Bloque en curso o, si no hay, el siguiente que aún no ha empezado.
  static HomeTodayEvent? nextEvent(List<HomeTodayEvent> events) {
    final pending = events
        .where((e) => e.kind == HomeEventKind.block && !e.completed)
        .toList();
    return pending
            .where((e) => e.status == ItemTimeStatus.inProgress)
            .firstOrNull ??
        pending.where((e) => e.status == ItemTimeStatus.upcoming).firstOrNull;
  }

  TodayHeroAction _actionFor(HomeTodayEvent? next) => switch (next?.type) {
    HomeEventType.study || HomeEventType.review => TodayHeroAction.focus,
    HomeEventType.sport when dashboard.nextTrainingDay != null =>
      TodayHeroAction.train,
    _ => TodayHeroAction.openPlanner,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final blocks = dashboard.todayEvents
        .where((e) => e.kind == HomeEventKind.block)
        .toList();
    final done = blocks.where((e) => e.completed).length;
    final next = nextEvent(dashboard.todayEvents);
    final action = _actionFor(next);
    final colors = context.colors;
    // Plana y con un toque del color de marca: destaca como tarjeta principal
    // sin degradados (principio 1 del sistema de diseño). No es un AppCard
    // porque Card agruparía en un solo nodo lo que el lector lee por partes.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensRadius.l),
        border: Border.all(color: colors.outlineVariant),
        // Sobre surface (no surfaceContainer): el texto secundario llega a 4,5:1
        // también en oscuro.
        color: Color.alphaBlend(
          colors.primary.withValues(alpha: AppPill.tintAlpha),
          colors.surface,
        ),
      ),
      padding: const EdgeInsets.all(TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Alineado (no estirado): el nodo del título mide lo que su texto.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              header: true,
              child: Text(
                l10n.homeTodayTitle,
                style: context.textStyles.titleSmall,
              ),
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= TokensLayout.twoColumnBreakpoint;
              final summary = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ProgressRing(done: done, total: blocks.length),
                  const SizedBox(width: TokensSpacing.m),
                  Expanded(
                    child: _NextUp(
                      next: next,
                      hasBlocks: blocks.isNotEmpty,
                      action: action,
                      starting: starting,
                      onAction: () => onAction(action),
                      showButton: wide,
                    ),
                  ),
                ],
              );
              // En pantallas anchas, las cifras a la derecha: la tarjeta no
              // deja media fila vacía.
              if (wide) {
                final stats = _Stats(dashboard: dashboard, focus: focus);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: summary),
                    const SizedBox(width: TokensSpacing.l),
                    Expanded(flex: 2, child: stats),
                  ],
                );
              }
              // En móvil, compacta: el botón a lo ancho bajo lo que toca y las
              // cifras en una línea fina, para que la agenda se vea sin
              // desplazar.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summary,
                  const SizedBox(height: TokensSpacing.s),
                  _ActionButton(
                    action: action,
                    hasEvent: next != null,
                    hasBlocks: blocks.isNotEmpty,
                    starting: starting,
                    onPressed: () => onAction(action),
                  ),
                  const SizedBox(height: TokensSpacing.s),
                  _StatsLine(dashboard: dashboard, focus: focus),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final value = total == 0 ? 0.0 : done / total;
    final complete = total > 0 && done >= total;
    final color = complete ? context.palette.success : context.colors.primary;
    return Semantics(
      label: l10n.homeTodayProgressSemantics(done, total),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: TokensSize.heroRing,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: context.motion(TokensDuration.slow),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: animated,
                strokeWidth: TokensSize.progressBar,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: context.colors.outlineVariant,
              ),
              // Dentro del trazo; con el texto muy grande se encoge en vez de
              // montarse encima (la etiqueta del lector ya lleva la cifra).
              Padding(
                padding: const EdgeInsets.all(
                  TokensSize.progressBar + TokensSpacing.xs,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: complete
                        ? Icon(Icons.check_rounded, color: color)
                        : Text(
                            total == 0 ? '–' : '$done/$total',
                            style: context.textStyles.titleLarge,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextUp extends StatelessWidget {
  const _NextUp({
    required this.next,
    required this.hasBlocks,
    required this.action,
    required this.starting,
    required this.onAction,
    this.showButton = true,
  });

  final HomeTodayEvent? next;
  final bool hasBlocks;
  final TodayHeroAction action;
  final bool starting;
  final VoidCallback onAction;

  /// En móvil el botón va aparte, a lo ancho de la tarjeta.
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final event = next;
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final button = _ActionButton(
      action: action,
      hasEvent: event != null,
      hasBlocks: hasBlocks,
      starting: starting,
      onPressed: onAction,
    );
    if (event == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasBlocks ? l10n.homeTodayAllDone : l10n.homeTodayEmpty,
            style: context.textStyles.titleSmall,
          ),
          if (showButton) ...[const SizedBox(height: TokensSpacing.s), button],
        ],
      );
    }
    final (typeIcon, typeColor) = homeEventVisual(context, event);
    final start = event.start;
    final end = event.end;
    final time = DateFormat.Hm();
    final when = start == null
        ? null
        : end == null
        ? time.format(start)
        : l10n.homeAgendaTimeRange(time.format(start), time.format(end));
    final now = event.status == ItemTimeStatus.inProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          now ? l10n.homeTodayNow : l10n.homeTodayNext,
          style: context.textStyles.labelLarge?.copyWith(
            color: now
                ? context.colors.primary
                : context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TokensSpacing.xxs),
        Row(
          children: [
            Icon(typeIcon, color: typeColor, size: TokensSize.iconS),
            const SizedBox(width: TokensSpacing.xs),
            Expanded(
              child: Text(
                readableEventTitle(
                  event.title.isEmpty
                      ? eventTypeLabel(context, event.type)
                      : event.title,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.titleMedium,
              ),
            ),
          ],
        ),
        if (when != null) Text(when, style: muted),
        if (showButton) ...[const SizedBox(height: TokensSpacing.s), button],
      ],
    );
  }
}

/// Botón principal de «Tu día»: concentrarse, entrenar o abrir el calendario.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.hasEvent,
    required this.hasBlocks,
    required this.starting,
    required this.onPressed,
  });

  final TodayHeroAction action;
  final bool hasEvent;
  final bool hasBlocks;
  final bool starting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final (label, icon) = switch (action) {
      TodayHeroAction.focus => (l10n.homeTodayFocus, Icons.timer_outlined),
      TodayHeroAction.train => (l10n.homeTodayTrain, Icons.play_arrow_rounded),
      TodayHeroAction.openPlanner => (
        !hasEvent && !hasBlocks
            ? l10n.homeTodayPlanDay
            : l10n.homeTodayOpenCalendar,
        Icons.calendar_month_outlined,
      ),
    };
    // Sin nada planificado, planificar es lo principal de la pantalla.
    return action == TodayHeroAction.openPlanner && (hasEvent || hasBlocks)
        ? AppSecondaryButton(
            label: label,
            icon: Icon(icon),
            onPressed: onPressed,
          )
        : AppPrimaryButton(
            label: label,
            icon: icon,
            loading: starting && action != TodayHeroAction.openPlanner,
            onPressed: onPressed,
          );
  }
}

/// Cifras de hoy en una sola línea (móvil): estudio, entreno y lo que falta
/// para subir de nivel. Cada cifra se lee como una frase.
class _StatsLine extends StatelessWidget {
  const _StatsLine({required this.dashboard, required this.focus});

  final HomeDashboard dashboard;
  final UsageFocus focus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final today = dashboard.today;
    final greeting = dashboard.greeting;
    final remaining = greeting.levelThreshold - greeting.levelXp;
    final items = <(IconData, Color, String, String)>[
      if (focus.includesAcademic)
        (
          Icons.menu_book_outlined,
          context.palette.study,
          today.studyMinutesPlanned > 0
              ? l10n.homeTodayStudyOf(
                  today.studyMinutesCompleted,
                  today.studyMinutesPlanned,
                )
              : l10n.homeTodayMinutes(today.studyMinutesCompleted),
          l10n.homeTodayStudy,
        ),
      if (focus.includesFitness)
        (
          Icons.fitness_center_rounded,
          context.palette.sessions,
          l10n.homeTodayMinutes(today.trainingMinutes),
          l10n.homeTodayTraining,
        ),
      (
        Icons.workspace_premium_outlined,
        context.palette.accent,
        l10n.homeTodayXp(remaining < 0 ? 0 : remaining, greeting.level + 1),
        l10n.commonLevel(greeting.level),
      ),
    ];
    final muted = context.textStyles.labelMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Wrap(
      spacing: TokensSpacing.m,
      runSpacing: TokensSpacing.xs,
      children: [
        for (final (icon, color, value, label) in items)
          Semantics(
            label: '$value, $label',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: TokensSize.iconXs),
                const SizedBox(width: TokensSpacing.xxs),
                // Con el texto grande se parte en vez de desbordar.
                Flexible(child: Text(value, style: muted)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Cifras de hoy: estudio y entreno (según el enfoque de uso) y el nivel con su
/// barra de XP.
class _Stats extends StatelessWidget {
  const _Stats({required this.dashboard, required this.focus});

  final HomeDashboard dashboard;
  final UsageFocus focus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final today = dashboard.today;
    final greeting = dashboard.greeting;
    final xp = greeting.levelThreshold <= 0
        ? 0.0
        : (greeting.levelXp / greeting.levelThreshold).clamp(0.0, 1.0);
    // Lo que falta para el siguiente nivel motiva más que «935 de 1100».
    final remaining = greeting.levelThreshold - greeting.levelXp;
    final tiles = <Widget>[
      if (focus.includesAcademic)
        _Stat(
          icon: Icons.menu_book_outlined,
          color: context.palette.study,
          value: today.studyMinutesPlanned > 0
              ? l10n.homeTodayStudyOf(
                  today.studyMinutesCompleted,
                  today.studyMinutesPlanned,
                )
              : l10n.homeTodayMinutes(today.studyMinutesCompleted),
          label: l10n.homeTodayStudy,
        ),
      if (focus.includesFitness)
        _Stat(
          icon: Icons.fitness_center_rounded,
          color: context.palette.sessions,
          value: l10n.homeTodayMinutes(today.trainingMinutes),
          label: l10n.homeTodayTraining,
        ),
      _Stat(
        icon: Icons.workspace_premium_outlined,
        color: context.palette.accent,
        value: l10n.commonLevel(greeting.level),
        label: l10n.homeTodayXp(
          remaining < 0 ? 0 : remaining,
          greeting.level + 1,
        ),
        progress: xp,
      ),
    ];
    // Columnas iguales si caben; con texto grande o poco ancho, una debajo de
    // otra a lo ancho.
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits =
            constraints.maxWidth / tiles.length >=
            context.scaled(TokensSize.heroStat);
        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, tile) in tiles.indexed) ...[
                if (i > 0) const SizedBox(height: TokensSpacing.s),
                tile,
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, tile) in tiles.indexed) ...[
                if (i > 0) const SizedBox(width: TokensSpacing.s),
                Expanded(child: tile),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.progress,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  /// Barra fina bajo la cifra (p. ej. la XP del nivel), de 0 a 1.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value, $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(TokensSpacing.s),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(TokensRadius.m),
        ),
        // Icono y etiqueta arriba, el valor debajo: todas las cifras con el
        // mismo tamaño y, si no caben, se parten en dos líneas.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: TokensSize.iconS),
                const SizedBox(width: TokensSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensSpacing.xxs),
            Text(value, style: context.textStyles.titleSmall),
            if (progress != null) ...[
              const SizedBox(height: TokensSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(TokensRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  color: color,
                  backgroundColor: context.colors.outlineVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
