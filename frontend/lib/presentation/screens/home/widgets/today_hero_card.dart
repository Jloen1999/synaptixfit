import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/home_event_kind.dart';
import '../../../../domain/enums/home_event_type.dart';
import '../../../../domain/enums/item_time_status.dart';
import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/enums/planner_enums.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'agenda_section.dart';

/// Las clases del horario: se ven en la agenda pero no cuentan como bloques
/// hechos (todavía no se dan por asistidas solas).
bool isClassEvent(HomeTodayEvent e) =>
    e.kind == HomeEventKind.block && e.type == HomeEventType.classSession;

/// El único botón de «Tu día»: concentrarse (Pomodoro del evento), empezar el
/// entreno, marcar como hecho o, sin nada pendiente, añadir al calendario.
enum TodayHeroAction { focus, train, markDone, addEvent }

/// «Tu día», lo primero de Inicio y su acción principal (vocabulario.md §4):
/// cuánto llevas de hoy (anillo), qué toca ahora o a continuación con **un
/// solo** botón directo y la cuenta atrás del próximo examen o entrega. Sin
/// cifras de XP ni de carga: esas viven en Progreso (ADR 0038).
class TodayHeroCard extends StatefulWidget {
  const TodayHeroCard({
    super.key,
    required this.dashboard,
    required this.focus,
    required this.onAction,
    this.starting = false,
    this.onMarkDone,
    this.completingIds = const {},
    this.nextDeadline,
    this.onOpenDeadline,
    this.now,
  });

  /// Próximo examen o entrega pendiente: cuenta atrás siempre a la vista.
  final HomeNextDeadline? nextDeadline;
  final VoidCallback? onOpenDeadline;
  final DateTime? now;

  /// Eventos que se están marcando (el botón se desactiva mientras).
  final Set<String> completingIds;

  final HomeDashboard dashboard;
  final UsageFocus focus;
  final ValueChanged<TodayHeroAction> onAction;

  /// Se está abriendo la sesión de entrenamiento.
  final bool starting;

  /// Marca como hecho el evento que toca ahora; sin él no se ofrece.
  final ValueChanged<HomeTodayEvent>? onMarkDone;

  /// Acción del botón para lo que toca ([next]); nula si no hay ninguna
  /// directa (una clase, una comida: se ven en la agenda).
  static TodayHeroAction? actionFor(
    HomeTodayEvent? next,
    HomeDashboard dashboard,
  ) => switch (next?.type) {
    null => TodayHeroAction.addEvent,
    HomeEventType.study || HomeEventType.review => TodayHeroAction.focus,
    // Solo con día de rutina: un partido o una carrera sueltos no deben
    // arrancar otra rutina (se marcan en la agenda con «Ya lo hice»).
    HomeEventType.sport when next?.routineDayId != null =>
      TodayHeroAction.train,
    HomeEventType.personal when next!.status == ItemTimeStatus.inProgress =>
      TodayHeroAction.markDone,
    _ => null,
  };

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

  @override
  State<TodayHeroCard> createState() => _TodayHeroCardState();
}

/// Al marcar como hecho lo que toca, el botón pulsado desaparece: el foco pasa
/// al título de «Tu día» y se anuncia qué se marcó (WCAG 2.4.3 y 4.1.3).
class _TodayHeroCardState extends State<TodayHeroCard> {
  final _titleFocus = FocusNode(debugLabel: 'home-today-title');

  /// Evento marcado desde aquí, hasta que llega hecho o falla.
  HomeTodayEvent? _marking;

  /// Ya se vio guardándose: si deja de estarlo sin quedar hecho, falló.
  bool _sawBusy = false;

  HomeDashboard get dashboard => widget.dashboard;
  UsageFocus get focus => widget.focus;
  bool get starting => widget.starting;
  Set<String> get completingIds => widget.completingIds;
  ValueChanged<TodayHeroAction> get onAction => widget.onAction;

  void _markDone(HomeTodayEvent event) {
    _marking = event;
    _sawBusy = false;
    widget.onMarkDone!(event);
  }

  @override
  void didUpdateWidget(TodayHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final marking = _marking;
    if (marking == null) return;
    final done = widget.dashboard.todayEvents.any(
      (e) => e.id == marking.id && e.completed,
    );
    if (done) {
      _marking = null;
      // El aviso de abajo ya dice qué se marcó: solo se devuelve el foco
      // (sin anuncio aparte, que se oiría dos veces).
      AppFocusAnchor.focusSoon(_titleFocus);
    } else if (widget.completingIds.contains(marking.id)) {
      _sawBusy = true;
    } else if (_sawBusy) {
      // Falló: el botón sigue ahí y el aviso de error lo explica.
      _marking = null;
    }
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final blocks = dashboard.todayEvents
        .where((e) => e.kind == HomeEventKind.block)
        .toList();
    // Las clases no cuentan en el anillo: nadie las marca como hechas y el día
    // se quedaba en «1/5» aunque hubieras ido a todas. Se nombran aparte.
    final counted = blocks.where((e) => !isClassEvent(e)).toList();
    final classes = blocks.length - counted.length;
    final done = counted.where((e) => e.completed).length;
    final next = TodayHeroCard.nextEvent(dashboard.todayEvents);
    final action = TodayHeroCard.actionFor(next, dashboard);
    final colors = context.colors;
    final deadline = focus.includesAcademic ? widget.nextDeadline : null;
    void act() {
      if (action == TodayHeroAction.markDone && widget.onMarkDone != null) {
        _markDone(next!);
      } else if (action != null) {
        onAction(action);
      }
    }

    final button = action == null
        ? null
        : _ActionButton(
            action: action,
            busy: action == TodayHeroAction.markDone
                ? completingIds.contains(next?.id)
                : starting && action == TodayHeroAction.train,
            onPressed: act,
          );
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
            child: AppFocusAnchor(
              focusNode: _titleFocus,
              child: Semantics(
                header: true,
                child: Text(
                  l10n.homeTodayTitle,
                  style: context.textStyles.titleSmall,
                ),
              ),
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProgressRing(done: done, total: counted.length),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: _NextUp(
                  next: next,
                  hasBlocks: blocks.isNotEmpty,
                  classes: classes,
                ),
              ),
            ],
          ),
          if (button != null) ...[
            const SizedBox(height: TokensSpacing.m),
            // En pantallas anchas el botón mide lo que su texto; en móvil, a
            // lo ancho de la tarjeta.
            LayoutBuilder(
              builder: (context, constraints) =>
                  constraints.maxWidth >= TokensLayout.twoColumnBreakpoint
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: button,
                    )
                  : button,
            ),
          ],
          if (deadline != null) ...[
            const SizedBox(height: TokensSpacing.s),
            _Countdown(
              deadline: deadline,
              now: widget.now ?? DateTime.now(),
              onOpen: widget.onOpenDeadline,
            ),
          ],
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
    this.classes = 0,
  });

  final HomeTodayEvent? next;

  /// Clases de hoy, que van fuera del anillo: se dicen en una línea aparte.
  final int classes;
  final bool hasBlocks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final event = next;
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final classesNote = classes == 0
        ? null
        : Text(
            l10n.homeTodayClassesNote(classes),
            style: context.textStyles.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          );
    if (event == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasBlocks ? l10n.homeTodayAllDone : l10n.homeTodayEmpty,
            style: context.textStyles.titleSmall,
          ),
          ?classesNote,
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
        ?classesNote,
      ],
    );
  }
}

/// El único botón de «Tu día», siempre el destacado de Inicio.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.busy,
    required this.onPressed,
  });

  final TodayHeroAction action;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final (label, icon) = switch (action) {
      TodayHeroAction.focus => (l10n.homeTodayFocus, AppIcons.focusTimer),
      TodayHeroAction.train => (l10n.homeTodayTrain, Icons.play_arrow_rounded),
      TodayHeroAction.markDone => (l10n.homeTodayMarkDone, AppIcons.markDone),
      TodayHeroAction.addEvent => (l10n.plannerAddBlock, AppIcons.add),
    };
    return AppPrimaryButton(
      label: label,
      icon: icon,
      loading: busy,
      onPressed: busy ? null : onPressed,
    );
  }
}

/// Cuenta atrás del próximo examen o entrega («Examen: Bioquímica · en 12
/// días»), siempre a la vista; al tocarla se abre esa entrega. Como los días
/// de «Tu semana»: la etiqueta va en el nodo del botón y solo se excluye el
/// contenido, para que el lector y el teclado conserven el toque y el foco.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.deadline, required this.now, this.onOpen});

  final HomeNextDeadline deadline;
  final DateTime now;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final days = AppDueDates.daysUntil(deadline.dueAt, now);
    final exam = deadline.type == DeadlineType.exam;
    final when = AppDueDates.countdown(context, deadline.dueAt, now);
    final text = exam
        ? l10n.homeCountdownExam(deadline.title, when)
        : l10n.homeCountdownDelivery(deadline.title, when);
    final color = days <= AppDueDates.urgentDays
        ? context.palette.warning
        : context.colors.onSurfaceVariant;
    return Semantics(
      button: onOpen != null,
      label: text,
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(TokensRadius.m),
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: TokensLayout.minTouchTarget,
              ),
              child: Row(
                children: [
                  Icon(
                    // Los mismos iconos que la agenda (un concepto, un icono).
                    exam ? AppIcons.exam : AppIcons.delivery,
                    size: TokensSize.iconS,
                    color: color,
                  ),
                  const SizedBox(width: TokensSpacing.xs),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: color,
                      ),
                    ),
                  ),
                  if (onOpen != null)
                    Icon(
                      AppIcons.next,
                      size: TokensSize.iconS,
                      color: context.colors.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
