import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/home_event_kind.dart';
import '../../../../domain/enums/home_event_type.dart';
import '../../../../domain/enums/item_time_status.dart';
import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../../domain/models/home/home_due_review.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Agenda: tira deslizable con hoy y los 6 días siguientes; debajo, lo que
/// hay el día elegido (eventos y entregas) y, hoy, los repasos urgentes.
///
/// Cada estudio, repaso, evento personal y entrega lleva su casilla «Marcar
/// como hecho» (ADR 0035; desmarcar devuelve la XP, lo decide el servidor); un
/// entreno de rutina lleva «Empezar» y uno suelto «Ya lo hice». Si el evento
/// adelanta una tarea de reto, la fila lo dice.
class AgendaSection extends StatefulWidget {
  const AgendaSection({
    super.key,
    required this.events,
    required this.upcoming,
    this.focus = UsageFocus.both,
    required this.reviews,
    required this.onOpenPlanner,
    required this.onOpenEvent,
    required this.onOpenReview,
    this.onReviewAll,
    this.onSetCompleted,
    this.onStartTraining,
    this.completingIds = const {},
    this.now,
  });

  /// Eventos de hoy (del resumen del servidor).
  final List<HomeTodayEvent> events;

  /// Eventos de los días siguientes.
  final List<HomeTodayEvent> upcoming;

  /// Enfoque de uso: los días siguientes solo muestran su ámbito (hoy ya llega
  /// filtrado del servidor).
  final UsageFocus focus;
  final List<HomeDueReview> reviews;
  final VoidCallback onOpenPlanner;

  /// Toque en un evento: abre ese día y ese bloque (o las entregas).
  final ValueChanged<HomeTodayEvent> onOpenEvent;
  final ValueChanged<HomeDueReview> onOpenReview;

  /// Repasa todos los pendientes seguidos (se muestra con dos o más).
  final VoidCallback? onReviewAll;

  /// Marca (true) o desmarca (false) un evento o una entrega; sin él, la
  /// agenda no ofrece casillas.
  final void Function(HomeTodayEvent event, bool completed)? onSetCompleted;

  /// «Empezar» de un entreno de rutina (el día de rutina del evento).
  final ValueChanged<HomeTodayEvent>? onStartTraining;

  /// Eventos que se están marcando o desmarcando.
  final Set<String> completingIds;

  /// Momento de referencia (inyectable en tests).
  final DateTime? now;

  /// Días de la tira, hoy incluido.
  static const days = 7;

  @override
  State<AgendaSection> createState() => _AgendaSectionState();
}

class _AgendaSectionState extends State<AgendaSection> {
  /// Índice del día elegido (0 = hoy).
  int _selected = 0;

  /// En móvil se ven los primeros [_collapsedEvents]; el resto con «Ver más».
  bool _expanded = false;
  static const _collapsedEvents = 3;

  List<HomeTodayEvent> _eventsOf(DateTime day, int index) {
    if (index == 0) return widget.events;
    return [
      for (final e in widget.upcoming)
        if (e.start != null &&
            DateUtils.isSameDay(e.start, day) &&
            _inFocus(e, widget.focus))
          e,
    ];
  }

  bool _compact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < TokensLayout.twoColumnBreakpoint;

  /// Lo pendiente primero no: se respeta el orden por hora, que es como se
  /// lee una agenda; solo se recorta la lista en móvil.
  List<HomeTodayEvent> _visibleEvents(
    BuildContext context,
    List<HomeTodayEvent> events,
  ) => !_compact(context) || _expanded
      ? events
      : events.take(_collapsedEvents).toList();

  int _hidden(BuildContext context, List<HomeTodayEvent> events) =>
      events.length - _visibleEvents(context, events).length;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final today = DateUtils.dateOnly(widget.now ?? DateTime.now());
    final days = [
      for (var i = 0; i < AgendaSection.days; i++)
        DateTime(today.year, today.month, today.day + i),
    ];
    final events = _eventsOf(days[_selected], _selected);
    final showReviews =
        _selected == 0 &&
        widget.focus.includesAcademic &&
        widget.reviews.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.homeAgendaTitle,
          actionLabel: l10n.homeAgendaOpenPlanner,
          onAction: widget.onOpenPlanner,
        ),
        _DayStrip(
          days: days,
          selected: _selected,
          events: [for (final (i, d) in days.indexed) _eventsOf(d, i)],
          onSelected: (i) => setState(() {
            _selected = i;
            _expanded = false;
          }),
        ),
        const SizedBox(height: TokensSpacing.s),
        if (events.isEmpty && !showReviews)
          // Una fila: un día sin nada no debe empujar el próximo entreno.
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensSpacing.m,
              vertical: TokensSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: TokensSpacing.m),
                // Sin botón propio: «Abrir planificador» ya está en el encabezado.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TokensSpacing.s,
                    ),
                    child: Text(
                      l10n.homeAgendaEmptyTitle,
                      style: context.textStyles.titleSmall,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (events.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final event in _visibleEvents(context, events))
                    _EventTile(
                      event: event,
                      isToday: _selected == 0,
                      busy: widget.completingIds.contains(event.id),
                      onTap: () => widget.onOpenEvent(event),
                      onSetCompleted: widget.onSetCompleted == null
                          ? null
                          : (completed) =>
                                widget.onSetCompleted!(event, completed),
                      onStartTraining: widget.onStartTraining == null
                          ? null
                          : () => widget.onStartTraining!(event),
                    ),
                  if (_hidden(context, events) > 0 || _expanded)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Semantics(
                        expanded: _expanded,
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          child: Text(
                            _expanded
                                ? l10n.homeAgendaShowLess
                                : l10n.homeAgendaShowMore(
                                    _hidden(context, events),
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (showReviews) ...[
            const SizedBox(height: TokensSpacing.s),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Una cabecera de grupo con el número en lugar de repetir
                  // «repaso pendiente» bajo cada fila.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensSpacing.m,
                      TokensSpacing.s,
                      TokensSpacing.m,
                      TokensSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.academicDueReviews(widget.reviews.length),
                              style: context.textStyles.labelLarge?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        if (widget.reviews.length > 1 &&
                            widget.onReviewAll != null)
                          TextButton.icon(
                            onPressed: widget.onReviewAll,
                            icon: const Icon(Icons.playlist_play_rounded),
                            label: Text(l10n.homeReviewAll),
                          ),
                      ],
                    ),
                  ),
                  for (final review in widget.reviews)
                    AppFocusOutline(
                      child: ListTile(
                        minTileHeight: TokensSize.listTileMin,
                        leading: Icon(
                          Icons.replay_circle_filled_outlined,
                          color: context.palette.study,
                        ),
                        title: Text(
                          review.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          l10n.homeAgendaReviewAction,
                          style: context.textStyles.labelLarge?.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                        onTap: () => widget.onOpenReview(review),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Si el evento pertenece a un ámbito que la persona usa (las entregas son de
/// estudios); el criterio vive en [UsageFocus].
bool _inFocus(HomeTodayEvent e, UsageFocus focus) =>
    e.kind == HomeEventKind.deadline
    ? focus.includesAcademic
    : focus.allowsEvent(e.type);

/// Lo que aún queda por hacer (ni hecho ni pasado): marca la ola de los puntos.
bool _isPending(HomeTodayEvent e) =>
    !e.completed && e.status != ItemTimeStatus.past;

/// Tira horizontal de días: día de la semana, número y un punto por evento
/// (hasta tres) del color de su tipo. El elegido va resaltado.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.days,
    required this.selected,
    required this.events,
    required this.onSelected,
  });

  final List<DateTime> days;
  final int selected;
  final List<List<HomeTodayEvent>> events;
  final ValueChanged<int> onSelected;

  /// «Hoy: 3 eventos, 2 pendientes»: lo mismo que dicen los puntos y su ola.
  static String _label(
    AppLocalizations l10n,
    String day,
    List<HomeTodayEvent> events,
  ) {
    final label = l10n.homeAgendaDaySemantics(day, events.length);
    final pending = events.where(_isPending).length;
    return pending == 0
        ? label
        : '$label, ${l10n.homeAgendaDayPending(pending)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final weekday = DateFormat.E();
    final longDay = DateFormat.MMMMEEEEd();
    final colors = context.colors;
    return SizedBox(
      height: context.scaled(TokensSize.dayChipHeight),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: TokensSpacing.s),
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = i == selected;
          final foreground = isSelected ? colors.onPrimary : colors.onSurface;
          return Semantics(
            button: true,
            selected: isSelected,
            label: _label(
              l10n,
              i == 0 ? l10n.homeAgendaToday : longDay.format(day),
              events[i],
            ),
            // El contenido se excluye dentro del InkWell: así se conservan su
            // acción y su foco en web y con lector de pantalla.
            child: AppFocusOutline(
              borderRadius: BorderRadius.circular(TokensRadius.l),
              child: Material(
                color: isSelected ? colors.primary : colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TokensRadius.l),
                  side: BorderSide(
                    color: isSelected ? colors.primary : colors.outlineVariant,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(TokensRadius.l),
                  onTap: () => onSelected(i),
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: context.scaled(TokensSize.dayChipWidth),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // «Aujourd'hui» no cabe en el chip: se reduce, no se parte.
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TokensSpacing.xxs,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                i == 0
                                    ? l10n.homeAgendaToday
                                    : weekday.format(day),
                                maxLines: 1,
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: foreground,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '${day.day}',
                            style: context.textStyles.titleMedium?.copyWith(
                              color: foreground,
                            ),
                          ),
                          const SizedBox(height: TokensSpacing.xxs),
                          _DayDots(
                            events: events[i],
                            onSelectedChip: isSelected,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Puntos de un día: uno por evento (hasta [maxDots], primero un tipo de
/// cada), del color de su tipo. Si queda algo por hacer, laten en ola suave
/// para que se note que hay tareas; con «reducir movimiento», quietos.
class _DayDots extends StatefulWidget {
  const _DayDots({required this.events, required this.onSelectedChip});

  final List<HomeTodayEvent> events;
  final bool onSelectedChip;

  static const maxDots = 3;

  /// Ciclos de la ola al aparecer: llama la atención y se para (WCAG 2.2.2).
  static const waveCycles = 2;

  @override
  State<_DayDots> createState() => _DayDotsState();
}

class _DayDotsState extends State<_DayDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: TokensDuration.pulse,
  );

  /// Ya se mostró la ola para este día (no se repite con cada refresco).
  bool _waved = false;

  bool get _pending => widget.events.any(_isPending);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_DayDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (_pending && !context.reduceMotion && !_waved) {
      _waved = true;
      _wave.repeat(count: _DayDots.waveCycles);
    } else if (!_pending || context.reduceMotion) {
      _wave.stop();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  /// Un evento de cada tipo primero; si sobran huecos, repetidos.
  List<HomeTodayEvent> _shown() {
    final seen = <HomeEventType>{};
    final distinct = [
      for (final e in widget.events)
        if (seen.add(e.type)) e,
    ];
    final rest = [
      for (final e in widget.events)
        if (!distinct.contains(e)) e,
    ];
    return [...distinct, ...rest].take(_DayDots.maxDots).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown();
    return SizedBox(
      height: TokensSize.dot,
      child: AnimatedBuilder(
        animation: _wave,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, event) in shown.indexed)
              _dot(context, event, _phase(i, shown.length)),
          ],
        ),
      ),
    );
  }

  /// 0-1 desplazado por punto: la ola recorre los puntos de izquierda a derecha.
  double _phase(int index, int count) {
    if (!_wave.isAnimating) return 0;
    final t = (_wave.value - index / (count + 1)) % 1;
    return 0.5 + 0.5 * math.cos(2 * math.pi * t);
  }

  Widget _dot(BuildContext context, HomeTodayEvent event, double phase) {
    // Sobre el día elegido (fondo de acento) los puntos van en su color de
    // texto para que se vean; lo ya hecho es un aro, no un punto relleno.
    final color = widget.onSelectedChip
        ? context.colors.onPrimary
        : eventColor(context, event);
    return Container(
      width: TokensSize.dot,
      height: TokensSize.dot,
      margin: const EdgeInsets.symmetric(horizontal: TokensSpacing.xxs),
      decoration: BoxDecoration(
        color: event.completed ? null : color,
        shape: BoxShape.circle,
        border: event.completed ? Border.all(color: color) : null,
        boxShadow: [
          if (phase > 0)
            BoxShadow(
              color: color.withValues(alpha: TokensOpacity.glow * phase),
              blurRadius: TokensSize.dot * phase,
              spreadRadius: TokensSpacing.xxs * phase,
            ),
        ],
      ),
    );
  }
}

/// Color del tipo de un evento (el mismo que su icono en la agenda).
Color eventColor(BuildContext context, HomeTodayEvent event) =>
    _EventTile.visual(context, event).$2;

/// Qué se puede hacer con un evento desde la agenda.
enum _EventAction { none, check, start, didIt }

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.onTap,
    this.isToday = true,
    this.busy = false,
    this.onSetCompleted,
    this.onStartTraining,
  });

  final HomeTodayEvent event;
  final VoidCallback onTap;
  final bool isToday;
  final bool busy;
  final ValueChanged<bool>? onSetCompleted;
  final VoidCallback? onStartTraining;

  /// Estudio, repaso, personal y entregas se marcan con casilla; los entrenos
  /// se empiezan (rutina) o se apuntan («Ya lo hice»); clases, descanso,
  /// comida y sueño no se marcan desde aquí.
  _EventAction get _action {
    if (event.kind == HomeEventKind.deadline) return _EventAction.check;
    // Un evento de otro día aún no se puede marcar: no se ofrece una acción
    // que siempre fallaría (las entregas sí se pueden adelantar).
    if (!isToday) return _EventAction.none;
    return switch (event.type) {
      HomeEventType.study ||
      HomeEventType.review ||
      HomeEventType.personal => _EventAction.check,
      HomeEventType.sport when event.routineDayId != null =>
        event.completed || !isToday || event.routineId == null
            ? _EventAction.none
            : _EventAction.start,
      HomeEventType.sport =>
        event.completed ? _EventAction.check : _EventAction.didIt,
      _ => _EventAction.none,
    };
  }

  /// Lo que aún no ha empezado no se puede marcar (lo dice el servidor con el
  /// estado): se explica en vez de mandar una petición que fallaría.
  void _toggle(BuildContext context, bool completed) {
    if (completed &&
        event.kind == HomeEventKind.block &&
        event.status == ItemTimeStatus.upcoming) {
      context.showSnack(context.localizations.plannerErrorBlockInFuture);
      return;
    }
    onSetCompleted?.call(completed);
  }

  Widget? _actionWidget(BuildContext context, String title) {
    final l10n = context.localizations;
    switch (_action) {
      case _EventAction.check when onSetCompleted != null:
        final label = event.completed
            ? l10n.homeAgendaUnmark(title)
            : l10n.homeAgendaMarkDone(title);
        // Mientras se guarda, la casilla sigue (desactivada) para no perder
        // el foco.
        return Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: SizedBox.square(
            dimension: TokensLayout.minTouchTarget,
            child: Checkbox(
              value: event.completed,
              semanticLabel: label,
              onChanged: busy ? null : (v) => _toggle(context, v ?? false),
            ),
          ),
        );
      case _EventAction.start when onStartTraining != null:
        // El lector oye qué se empieza, no solo «Empezar».
        return Semantics(
          label: '${l10n.homeTrainingStart}: $title',
          excludeSemantics: true,
          button: true,
          onTap: onStartTraining,
          child: TextButton(
            onPressed: onStartTraining,
            child: Text(l10n.homeTrainingStart),
          ),
        );
      case _EventAction.didIt when onSetCompleted != null:
        return Semantics(
          label: '${l10n.homeAgendaDidIt}: $title',
          excludeSemantics: true,
          button: true,
          enabled: !busy,
          onTap: busy ? null : () => _toggle(context, true),
          child: TextButton(
            onPressed: busy ? null : () => _toggle(context, true),
            child: Text(l10n.homeAgendaDidIt),
          ),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final time = DateFormat.Hm();
    final (icon, color) = visual(context, event);
    final start = event.start;
    final end = event.end;
    final when = start == null
        ? null
        : end == null
        ? time.format(start)
        : l10n.homeAgendaTimeRange(time.format(start), time.format(end));
    final subject = event.subjectName;
    final subtitle = [
      ?when,
      eventTypeLabel(context, event.type),
      // Sin repetir la asignatura cuando el evento ya se llama así.
      if (subject != null &&
          subject.isNotEmpty &&
          subject.toLowerCase() != event.title.toLowerCase())
        readableEventTitle(subject),
    ].join(' · ');
    // La tarea de reto que avanza con este evento, en vez de repetirla aparte.
    final tasks = [
      for (final t in event.tasks)
        t.title == null
            ? l10n.homeAgendaTaskChallenge(t.challengeTitle)
            : l10n.homeAgendaTask(t.title!, t.challengeTitle),
    ];
    final title = event.title.isEmpty
        ? eventTypeLabel(context, event.type)
        : readableEventTitle(event.title);

    // Lo que ya pasó sin hacerse se dice (no se ve igual que lo que viene):
    // una entrega vencida en rojo; un bloque sin hacer, en aviso.
    final statusPill = event.completed
        ? null
        : switch (event.status) {
            ItemTimeStatus.missed when event.kind == HomeEventKind.deadline =>
              AppPill(
                icon: Icons.event_busy_rounded,
                label: l10n.homeAgendaOverdue,
                color: context.colors.error,
              ),
            ItemTimeStatus.missed => AppPill(
              icon: AppIcons.history,
              label: l10n.homeAgendaMissed,
              color: context.palette.warning,
            ),
            ItemTimeStatus.inProgress => AppPill(
              icon: Icons.play_circle_outline_rounded,
              label: l10n.homeAgendaNow,
              color: context.colors.primary,
            ),
            _ => null,
          };
    // Con texto grande la pastilla baja bajo el subtítulo para no comerse el título.
    final largeText = context.largeText;
    final subtitleText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          subtitle,
          maxLines: largeText ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        for (final task in tasks)
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: TokensSize.iconXs,
                color: context.palette.accent,
              ),
              const SizedBox(width: TokensSpacing.xxs),
              Expanded(
                child: Text(
                  task,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
    final action = _actionWidget(context, title);

    // La fila abre el evento y la acción (casilla, «Empezar», «Ya lo hice»)
    // va al lado, como hermana: sin una zona de toque dentro de otra.
    final tile = AppFocusOutline(
      child: ListTile(
        minTileHeight: TokensSize.listTileMin,
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(TokensSpacing.s),
          decoration: BoxDecoration(
            color: color.withValues(alpha: AppPill.tintAlpha),
            borderRadius: BorderRadius.circular(TokensRadius.m),
          ),
          child: Icon(icon, color: color, size: TokensSize.iconS),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: event.completed
              ? context.textStyles.bodyLarge?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: context.colors.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: largeText && statusPill != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  subtitleText,
                  const SizedBox(height: TokensSpacing.xs),
                  statusPill,
                ],
              )
            : subtitleText,
        trailing: action != null
            ? (largeText ? null : statusPill)
            : event.completed
            ? Tooltip(
                message: l10n.homeAgendaCompleted,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: context.palette.success,
                  semanticLabel: l10n.homeAgendaCompleted,
                ),
              )
            : largeText
            ? null
            : statusPill,
      ),
    );
    if (action == null) return tile;
    // Con texto grande un botón con texto («Empezar», «Ya lo hice») baja bajo
    // la fila: al lado dejaría el título sin sitio. La casilla cabe siempre.
    if (largeText && _action != _EventAction.check) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile,
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: TokensSize.iconM + TokensSpacing.m * 2,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: action,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: tile),
        action,
      ],
    );
  }

  static (IconData, Color) visual(BuildContext context, HomeTodayEvent event) {
    final type = event.type;
    if (event.kind == HomeEventKind.deadline) {
      return (Icons.assignment_late_outlined, context.palette.warning);
    }
    return switch (type) {
      HomeEventType.study => (Icons.menu_book_outlined, context.palette.study),
      HomeEventType.classSession => (
        Icons.school_outlined,
        context.colors.tertiary,
      ),
      HomeEventType.review => (Icons.replay_rounded, context.palette.study),
      HomeEventType.sport => (
        Icons.fitness_center_rounded,
        context.colors.secondary,
      ),
      HomeEventType.rest => (
        Icons.self_improvement_rounded,
        context.colors.primary,
      ),
      HomeEventType.meal => (Icons.restaurant_outlined, context.colors.primary),
      HomeEventType.sleep => (Icons.bedtime_outlined, context.colors.primary),
      HomeEventType.exam ||
      HomeEventType.delivery ||
      HomeEventType.presentation => (
        Icons.assignment_late_outlined,
        context.palette.warning,
      ),
      HomeEventType.personal => (
        Icons.person_outline_rounded,
        context.colors.onSurfaceVariant,
      ),
      HomeEventType.other => (
        Icons.event_outlined,
        context.colors.onSurfaceVariant,
      ),
    };
  }
}

/// Icono y color de un evento de la agenda (los mismos en «Tu día»).
(IconData, Color) homeEventVisual(BuildContext context, HomeTodayEvent event) =>
    _EventTile.visual(context, event);

/// Los calendarios importados (ICS, horarios escaneados) suelen traer los
/// nombres en mayúsculas: «AMPLIACIÓN DE MATEMÁTICAS» se muestra como
/// «Ampliación de matemáticas», más fácil de leer. Lo demás, tal cual.
String readableEventTitle(String title) {
  final letters = title.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
  if (letters.length < 4 || title != title.toUpperCase()) return title;
  final lower = title.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

/// Nombre traducido del tipo de evento.
String eventTypeLabel(BuildContext context, HomeEventType type) {
  final l10n = context.localizations;
  return switch (type) {
    HomeEventType.study => l10n.homeEventStudy,
    HomeEventType.classSession => l10n.homeEventClass,
    HomeEventType.review => l10n.homeEventReview,
    HomeEventType.sport => l10n.homeEventSport,
    HomeEventType.rest => l10n.homeEventRest,
    HomeEventType.meal => l10n.homeEventMeal,
    HomeEventType.sleep => l10n.homeEventSleep,
    HomeEventType.exam => l10n.homeEventExam,
    HomeEventType.delivery => l10n.homeEventDelivery,
    HomeEventType.presentation => l10n.homeEventPresentation,
    HomeEventType.personal => l10n.homeEventPersonal,
    HomeEventType.other => l10n.homeEventOther,
  };
}
