import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/planner/calendar_block.dart';
import '../../../../domain/models/planner/planner_week.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import 'planner_visuals.dart';
import 'time_block_tile.dart';
import 'time_grid_painter.dart';
import 'week_grid_geometry.dart';

/// Lienzo continuo de la semana: cabecera de días y eje horario fijos, y una
/// rejilla desplazable en ambos ejes con los bloques posicionados.
///
/// Toda la conversión hora ↔ píxel la hace [WeekGridGeometry]; aquí solo se
/// guarda el estado efímero del gesto (vista previa del arrastre).
class WeekCanvas extends StatefulWidget {
  const WeekCanvas({
    super.key,
    required this.weekStart,
    required this.blocks,
    required this.titles,
    required this.busyIds,
    required this.now,
    this.focusAt,
    required this.onSlotTap,
    required this.onBlockTap,
    required this.onReschedule,
    required this.onLockedBlockTouched,
  });

  final DateTime weekStart;
  final List<CalendarBlock> blocks;
  final Map<String, String> titles;
  final Set<String> busyIds;
  final DateTime now;

  /// Momento en el que se coloca la vista al abrir (un bloque pedido); sin él,
  /// en «ahora».
  final DateTime? focusAt;
  final ValueChanged<DateTime> onSlotTap;
  final ValueChanged<CalendarBlock> onBlockTap;
  final void Function(CalendarBlock block, DateTime start, DateTime end)
  onReschedule;
  final ValueChanged<CalendarBlock> onLockedBlockTouched;

  static const axisWidth = 52.0;
  static const headerHeight = 48.0;
  static const minDayWidth = 108.0;
  static const hourHeight = 60.0;

  @override
  State<WeekCanvas> createState() => _WeekCanvasState();
}

class _WeekCanvasState extends State<WeekCanvas> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  final _axis = ScrollController();
  final _header = ScrollController();

  String? _activeId;
  Offset _dragOffset = Offset.zero;
  double _resizeDy = 0;
  bool _resizing = false;
  TimeRange? _preview;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _vertical.addListener(() {
      if (_axis.hasClients) _axis.jumpTo(_vertical.offset);
    });
    _horizontal.addListener(() {
      if (_header.hasClients) _header.jumpTo(_horizontal.offset);
    });
  }

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    _axis.dispose();
    _header.dispose();
    super.dispose();
  }

  /// Al abrir la semana: una hora antes de ahora (como pronto, las 7:00) y,
  /// si hoy cae en ella, con hoy como primera columna visible: los días ya
  /// pasados quedan a la izquierda, a un desplazamiento.
  void _scrollToNow(WeekGridGeometry g) {
    if (_initialScrollDone) return;
    _initialScrollDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchor = widget.focusAt ?? widget.now;
      if (_vertical.hasClients) {
        final nowMin = WeekGridGeometry.minutesOfDay(anchor);
        final target = math.max(7 * 60, nowMin - 60);
        _vertical.jumpTo(
          g.minutesToY(target).clamp(0.0, _vertical.position.maxScrollExtent),
        );
      }
      final today = g.dayIndexOf(anchor, widget.weekStart);
      if (today != null && _horizontal.hasClients) {
        _horizontal.jumpTo(
          g.dayLeft(today).clamp(0.0, _horizontal.position.maxScrollExtent),
        );
      }
    });
  }

  void _clearGesture() {
    setState(() {
      _activeId = null;
      _preview = null;
      _dragOffset = Offset.zero;
      _resizeDy = 0;
      _resizing = false;
    });
  }

  void _commit(CalendarBlock block) {
    final preview = _preview;
    _clearGesture();
    if (preview == null) return;
    if (preview.start == block.start && preview.end == block.end) return;
    widget.onReschedule(block, preview.start, preview.end);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - WeekCanvas.axisWidth;
        final geometry = WeekGridGeometry(
          dayWidth: math.max(available / 7, WeekCanvas.minDayWidth),
          hourHeight: WeekCanvas.hourHeight,
        );
        _scrollToNow(geometry);
        return Column(
          children: [
            SizedBox(
              height: WeekCanvas.headerHeight,
              child: Row(
                children: [
                  const SizedBox(width: WeekCanvas.axisWidth),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _header,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: _DayHeader(
                        geometry: geometry,
                        weekStart: widget.weekStart,
                        now: widget.now,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: WeekCanvas.axisWidth,
                    child: SingleChildScrollView(
                      controller: _axis,
                      physics: const NeverScrollableScrollPhysics(),
                      // Mismo hueco que la cuadrícula: siguen alineadas.
                      padding: const EdgeInsets.only(
                        bottom: TokensLayout.fabClearance,
                      ),
                      child: _HourAxis(geometry: geometry),
                    ),
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: _vertical,
                      child: SingleChildScrollView(
                        controller: _vertical,
                        // Hueco al final: «Añadir» (flotante) no tapa las
                        // últimas horas (vocabulario §4: nada flotante tapa).
                        padding: const EdgeInsets.only(
                          bottom: TokensLayout.fabClearance,
                        ),
                        child: Scrollbar(
                          controller: _horizontal,
                          notificationPredicate: (n) => n.depth == 0,
                          child: SingleChildScrollView(
                            controller: _horizontal,
                            scrollDirection: Axis.horizontal,
                            child: _grid(context, geometry),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _grid(BuildContext context, WeekGridGeometry g) {
    final children = <Widget>[];
    CalendarBlock? active;

    // Bloques por día, repartidos en carriles si se solapan.
    final byDay = <int, List<CalendarBlock>>{};
    for (final b in widget.blocks) {
      final day = g.dayIndexOf(b.start, widget.weekStart);
      if (day == null) continue;
      (byDay[day] ??= []).add(b);
    }
    for (final entry in byDay.entries) {
      final dayBlocks = entry.value;
      final lanes = WeekGridGeometry.assignLanes([
        for (final b in dayBlocks) (start: b.start, end: b.end),
      ]);
      for (var i = 0; i < dayBlocks.length; i++) {
        final block = dayBlocks[i];
        if (block.id == _activeId) {
          active = block;
          continue;
        }
        final extent = g.verticalExtent((start: block.start, end: block.end));
        if (extent == null) continue;
        final laneWidth = g.dayWidth / lanes[i].lanes;
        children.add(
          Positioned(
            key: ValueKey(block.id),
            left: g.dayLeft(entry.key) + lanes[i].lane * laneWidth + 2,
            top: extent.top + 1,
            width: laneWidth - 4,
            height: math.max(extent.height - 2, 18),
            child: _ordered(block, _tile(block, g, block.start, block.end)),
          ),
        );
      }
    }

    // El bloque que se arrastra se pinta encima, a todo el ancho del día.
    if (active != null) {
      final range = _preview ?? (start: active.start, end: active.end);
      final day = g.dayIndexOf(range.start, widget.weekStart) ?? 0;
      final extent = g.verticalExtent(range);
      if (extent != null) {
        children.add(
          Positioned(
            key: ValueKey(active.id),
            left: g.dayLeft(day) + 2,
            top: extent.top + 1,
            width: g.dayWidth - 4,
            height: math.max(extent.height - 2, 18),
            child: _ordered(active, _tile(active, g, range.start, range.end)),
          ),
        );
      }
    }

    // Orden de foco cronológico (día a día y por hora). El orden geométrico por
    // defecto recorrería la rejilla por filas, saltando de un día a otro.
    return SizedBox(
      width: g.gridWidth,
      height: g.gridHeight,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => widget.onSlotTap(
                  g.slotAt(
                    widget.weekStart,
                    d.localPosition.dx,
                    d.localPosition.dy,
                  ),
                ),
                child: CustomPaint(
                  painter: TimeGridPainter(
                    geometry: g,
                    weekStart: widget.weekStart,
                    now: widget.now,
                    lineColor: context.colors.outlineVariant,
                    halfLineColor: context.colors.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                    pastColor: context.colors.onSurface.withValues(alpha: 0.04),
                    todayColor: context.colors.primary.withValues(alpha: 0.05),
                    nowColor: context.colors.error,
                  ),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _ordered(CalendarBlock block, Widget child) => FocusTraversalOrder(
    order: NumericFocusOrder(block.start.millisecondsSinceEpoch.toDouble()),
    child: child,
  );

  Widget _tile(
    CalendarBlock block,
    WeekGridGeometry g,
    DateTime start,
    DateTime end,
  ) {
    return TimeBlockTile(
      block: block,
      title:
          widget.titles[block.id] ??
          (block.topics?.isNotEmpty ?? false
              ? block.topics!
              : block.type.label(context)),
      start: start,
      end: end,
      busy: widget.busyIds.contains(block.id),
      dragging: _activeId == block.id,
      onTap: () => widget.onBlockTap(block),
      onLockedTouched: () => widget.onLockedBlockTouched(block),
      onDragStart: () => setState(() {
        _activeId = block.id;
        _dragOffset = Offset.zero;
        _preview = (start: block.start, end: block.end);
      }),
      onDragUpdate: (offset) => setState(() {
        _dragOffset = offset;
        _preview = g.moveBy(
          (start: block.start, end: block.end),
          widget.weekStart,
          dx: _dragOffset.dx,
          dy: _dragOffset.dy,
        );
      }),
      onDragEnd: () => _commit(block),
      onResizeUpdate: (delta) => setState(() {
        if (!_resizing) {
          _resizing = true;
          _activeId = block.id;
          _resizeDy = 0;
        }
        _resizeDy += delta;
        _preview = (
          start: block.start,
          end: g.resizeEndBy((
            start: block.start,
            end: block.end,
          ), dy: _resizeDy),
        );
      }),
      onResizeEnd: () => _commit(block),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.geometry,
    required this.weekStart,
    required this.now,
  });

  final WeekGridGeometry geometry;
  final DateTime weekStart;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          SizedBox(
            width: geometry.dayWidth,
            child: _dayLabel(context, PlannerWeek.dayOf(weekStart, i)),
          ),
      ],
    );
  }

  Widget _dayLabel(BuildContext context, DateTime day) {
    final isToday = PlannerWeek.isSameDay(day, now);
    // «Hoy, viernes 24 de octubre»: el resalte de color también se dice. Cada
    // día es un encabezado para saltar de columna en columna.
    final date = PlannerFormats.longDate(day);
    return Semantics(
      header: true,
      label: isToday ? context.localizations.plannerTodayDate(date) : date,
      excludeSemantics: true,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TokensSpacing.s,
            vertical: TokensSpacing.xs,
          ),
          decoration: isToday
              ? BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(TokensRadius.pill),
                )
              : null,
          child: Text(
            PlannerFormats.dayShort(day),
            style: context.textStyles.labelLarge?.copyWith(
              color: isToday
                  ? context.colors.onPrimary
                  : context.colors.onSurfaceVariant,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _HourAxis extends StatelessWidget {
  const _HourAxis({required this.geometry});

  final WeekGridGeometry geometry;

  @override
  Widget build(BuildContext context) {
    final style = context.textStyles.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return SizedBox(
      height: geometry.gridHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var h = geometry.startHour; h < geometry.endHour; h++)
            Positioned(
              top: geometry.minutesToY(h * 60) + 2,
              right: TokensSpacing.s,
              child: Text(PlannerFormats.minutes(h * 60), style: style),
            ),
        ],
      ),
    );
  }
}
