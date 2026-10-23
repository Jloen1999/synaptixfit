import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/home_event_kind.dart';
import '../../../../domain/enums/home_event_type.dart';
import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../../domain/models/home/home_due_review.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Agenda: tira deslizable con hoy y los 6 días siguientes; debajo, lo que
/// hay el día elegido (bloques y entregas) y, hoy, los repasos urgentes.
class AgendaSection extends StatefulWidget {
  const AgendaSection({
    super.key,
    required this.events,
    required this.upcoming,
    this.focus = UsageFocus.both,
    required this.reviews,
    required this.onOpenPlanner,
    required this.onOpenReview,
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
  final ValueChanged<HomeDueReview> onOpenReview;

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
          counts: [for (final (i, d) in days.indexed) _eventsOf(d, i).length],
          onSelected: (i) => setState(() => _selected = i),
        ),
        const SizedBox(height: TokensSpacing.s),
        if (events.isEmpty && !showReviews)
          AppCard(
            child: AppEmptyState.compact(
              icon: Icons.event_available_outlined,
              title: l10n.homeAgendaEmptyTitle,
              action: AppSecondaryButton(
                label: l10n.homeAgendaPlanAction,
                onPressed: widget.onOpenPlanner,
              ),
            ),
          )
        else ...[
          if (events.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
              child: Column(
                children: [
                  for (final event in events)
                    _EventTile(event: event, onTap: widget.onOpenPlanner),
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
                          maxLines: 1,
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

/// Tira horizontal de días: día de la semana, número y un punto por evento
/// (hasta tres). El elegido va resaltado.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.days,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final List<DateTime> days;
  final int selected;
  final List<int> counts;
  final ValueChanged<int> onSelected;

  static const _maxDots = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final weekday = DateFormat.E('es');
    final longDay = DateFormat.MMMMEEEEd('es');
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
            label: l10n.homeAgendaDaySemantics(
              i == 0 ? l10n.homeAgendaToday : longDay.format(day),
              counts[i],
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
                          Text(
                            i == 0 ? l10n.homeAgendaToday : weekday.format(day),
                            style: context.textStyles.labelSmall?.copyWith(
                              color: foreground,
                            ),
                          ),
                          Text(
                            '${day.day}',
                            style: context.textStyles.titleMedium?.copyWith(
                              color: foreground,
                            ),
                          ),
                          const SizedBox(height: TokensSpacing.xxs),
                          SizedBox(
                            height: TokensSize.dot,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (
                                  var d = 0;
                                  d < math.min(counts[i], _maxDots);
                                  d++
                                )
                                  Container(
                                    width: TokensSize.dot,
                                    height: TokensSize.dot,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: TokensSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colors.onPrimary
                                          : colors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
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

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.onTap});

  final HomeTodayEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final time = DateFormat.Hm('es');
    final (icon, color) = _visual(context, event.type);
    final start = event.start;
    final end = event.end;
    final when = start == null
        ? null
        : end == null
        ? time.format(start)
        : l10n.homeAgendaTimeRange(time.format(start), time.format(end));
    final subtitle = [
      ?when,
      eventTypeLabel(context, event.type),
      if (event.subjectName != null && event.subjectName!.isNotEmpty)
        event.subjectName!,
    ].join(' · ');

    return AppFocusOutline(
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
          event.title.isEmpty
              ? eventTypeLabel(context, event.type)
              : event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: event.completed
              ? context.textStyles.bodyLarge?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: context.colors.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: event.completed
            ? Tooltip(
                message: l10n.homeAgendaCompleted,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: context.palette.success,
                  semanticLabel: l10n.homeAgendaCompleted,
                ),
              )
            : null,
      ),
    );
  }

  (IconData, Color) _visual(BuildContext context, HomeEventType type) {
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
      HomeEventType.other => (
        Icons.event_outlined,
        context.colors.onSurfaceVariant,
      ),
    };
  }
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
    HomeEventType.other => l10n.homeEventOther,
  };
}
