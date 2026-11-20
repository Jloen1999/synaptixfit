import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'agenda_section.dart';

/// «Ayer quedó sin marcar» (ADR 0059): cada evento con su nombre, día y hora
/// y tres botones: **Lo hice**, **Pasar a otro día** (eliges el día) y
/// **Quitar** (rojo y aparte; lo borra del calendario con «Deshacer»). Con
/// varios, se ve el primero y «Ver los N». Qué eventos salen lo decide el
/// servidor; lo resuelve el bloc de Inicio.
class MissedEventsCard extends StatefulWidget {
  const MissedEventsCard({
    super.key,
    required this.events,
    required this.onDone,
    required this.onMove,
    required this.onRemove,
    this.onOpen,
    this.busyIds = const {},
    this.now,
  });

  /// Lo de ayer sin marcar, el más reciente primero.
  final List<HomeTodayEvent> events;
  final ValueChanged<HomeTodayEvent> onDone;

  /// El evento va al día elegido a la misma hora ([start] y [end] nuevos).
  final void Function(HomeTodayEvent event, DateTime start, DateTime end)
  onMove;
  final ValueChanged<HomeTodayEvent> onRemove;

  /// Abre el evento en el calendario.
  final ValueChanged<HomeTodayEvent>? onOpen;

  /// Eventos con una acción en curso.
  final Set<String> busyIds;
  final DateTime? now;

  @override
  State<MissedEventsCard> createState() => _MissedEventsCardState();
}

class _MissedEventsCardState extends State<MissedEventsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final events = widget.events;
    final visible = _expanded ? events : events.take(1).toList();
    return Semantics(
      container: true,
      child: AppCard(
        padding: const EdgeInsets.all(TokensSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.homeMissedTitle(events.length),
                style: context.textStyles.titleMedium,
              ),
            ),
            for (final (i, event) in visible.indexed) ...[
              if (i > 0) const Divider(height: TokensSpacing.l),
              const SizedBox(height: TokensSpacing.s),
              _MissedItem(
                event: event,
                busy: widget.busyIds.contains(event.id),
                now: widget.now ?? DateTime.now(),
                onDone: () => widget.onDone(event),
                onMove: (start, end) => widget.onMove(event, start, end),
                onRemove: () => widget.onRemove(event),
                onOpen: widget.onOpen == null
                    ? null
                    : () => widget.onOpen!(event),
              ),
            ],
            if (events.length > 1) ...[
              const SizedBox(height: TokensSpacing.s),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  expanded: _expanded,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded
                          ? l10n.homeAgendaShowLess
                          : l10n.homeMissedSeeAll(events.length),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MissedItem extends StatelessWidget {
  const _MissedItem({
    required this.event,
    required this.busy,
    required this.now,
    required this.onDone,
    required this.onMove,
    required this.onRemove,
    this.onOpen,
  });

  final HomeTodayEvent event;
  final VoidCallback? onOpen;
  final bool busy;
  final DateTime now;
  final VoidCallback onDone;
  final void Function(DateTime start, DateTime end) onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final (icon, color) = homeEventVisual(context, event);
    final name = event.title.isEmpty
        ? eventTypeLabel(context, event.type)
        : readableEventTitle(event.title);
    final start = event.start;
    final end = event.end;
    final time = DateFormat.Hm(l10n.localeName);
    final when = start == null
        ? null
        : [
            toBeginningOfSentenceCase(
              DateFormat.MMMEd(l10n.localeName).format(start),
            ),
            if (end == null)
              time.format(start)
            else
              l10n.homeAgendaTimeRange(time.format(start), time.format(end)),
          ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCardTapArea(
          onTap: onOpen,
          semanticHint: l10n.homeTodayOpenEventHint,
          child: Row(
            children: [
              // El tipo va en el icono y en la línea de abajo, no solo en el
              // color (WCAG 1.4.1).
              Icon(icon, color: color, size: TokensSize.iconM),
              const SizedBox(width: TokensSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall,
                    ),
                    Text(
                      [?when, eventTypeLabel(context, event.type)].join(' · '),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
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
        const SizedBox(height: TokensSpacing.s),
        // «Quitar» al final y aparte del resto (vocabulario §4); si no cabe,
        // baja de línea alineado al final.
        OverflowBar(
          spacing: TokensSpacing.s,
          overflowSpacing: TokensSpacing.s,
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.end,
          children: [
            Wrap(
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  label: l10n.homeMissedDidItFor(name),
                  excludeSemantics: true,
                  button: true,
                  enabled: !busy,
                  onTap: busy ? null : onDone,
                  child: FilledButton.tonal(
                    onPressed: busy ? null : onDone,
                    child: Text(l10n.homeMissedDidIt),
                  ),
                ),
                if (start != null && end != null)
                  Semantics(
                    label: l10n.homeMissedMoveFor(name),
                    excludeSemantics: true,
                    button: true,
                    enabled: !busy,
                    onTap: busy ? null : () => _move(context, start, end),
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _move(context, start, end),
                      child: Text(l10n.homeMissedMove),
                    ),
                  ),
              ],
            ),
            // Borrar en rojo y aparte del resto (vocabulario §4).
            Padding(
              padding: EdgeInsets.zero,
              child: Semantics(
                label: l10n.homeMissedRemoveFor(name),
                excludeSemantics: true,
                button: true,
                enabled: !busy,
                onTap: busy ? null : onRemove,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.error,
                    side: BorderSide(color: context.colors.error),
                  ),
                  onPressed: busy ? null : onRemove,
                  child: Text(l10n.homeMissedRemove),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _move(BuildContext context, DateTime start, DateTime end) async {
    final day = await showMoveDaySheet(context, from: start, now: now);
    if (day == null) return;
    final newStart = DateTime(
      day.year,
      day.month,
      day.day,
      start.hour,
      start.minute,
    );
    onMove(newStart, newStart.add(end.difference(start)));
  }
}
