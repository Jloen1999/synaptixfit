import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/planner/calendar_block.dart';
import '../../../../domain/models/planner/planner_week.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'planner_visuals.dart';
import 'time_block_tile.dart';
import 'time_grid_painter.dart';
import 'week_grid_geometry.dart';

/// Lienzo continuo de la semana: cabecera de días y eje horario fijos, y una
/// rejilla desplazable en ambos ejes con los bloques posicionados. El día va
/// entero, de 0:00 a 24:00, y lo que cruza la medianoche se pinta en sus dos
/// días (ADR 0050). Si los 7 días no caben, una tira arriba lleva a cualquiera
/// y marca el que se ve, y la cabecera de días se queda en una línea fina que
/// solo dice qué columna es cada día (ADR 0060). Tocar o mantener pulsado un
/// hueco vacío añade ahí.
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
    this.focusDay,
    this.onVisibleDayChanged,
    this.summary,
    required this.onSlotTap,
    this.onSlotLongPress,
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

  /// Día en que se abre (p. ej. desde «Tu semana»), sin hora concreta: se
  /// coloca en su primer evento.
  final DateTime? focusDay;

  /// Día de la semana que se ve (0 = lunes) cuando no caben los 7; nulo si
  /// caben todos. La página lo usa para enseñar «Hoy» solo cuando hace falta.
  final ValueChanged<int?>? onVisibleDayChanged;

  /// Lo que va entre la tira de días y la rejilla (las cifras de la semana).
  final Widget? summary;
  final ValueChanged<DateTime> onSlotTap;

  /// Mantener pulsado un hueco vacío (que empieza en ese momento): añade ahí,
  /// igual que tocarlo. Sobre un evento, la pulsación larga lo arrastra.
  final ValueChanged<DateTime>? onSlotLongPress;
  final ValueChanged<CalendarBlock> onBlockTap;
  final void Function(CalendarBlock block, DateTime start, DateTime end)
  onReschedule;
  final ValueChanged<CalendarBlock> onLockedBlockTouched;

  static const axisWidth = 52.0;
  static const headerHeight = 48.0;

  /// Cabecera de días cuando no caben los 7: la tira ya dice la fecha y lleva
  /// a cada día; esta línea solo nombra las columnas que se ven.
  static const compactHeaderHeight = TokensSize.calendarDayHeaderCompact;
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

  /// Geometría del último dibujo (la usan la tira y el desplazamiento).
  WeekGridGeometry? _geometry;

  /// Día marcado en la tira: el elegido o, al desplazarse, el primero visible.
  int _selectedDay = 0;

  /// Se está yendo a un día de la tira: el desplazamiento no cambia la marca.
  bool _jumpingToDay = false;

  /// Lo último avisado con [WeekCanvas.onVisibleDayChanged].
  int? _reportedDay;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _vertical.addListener(() {
      if (_axis.hasClients) _axis.jumpTo(_vertical.offset);
    });
    _horizontal.addListener(() {
      if (_header.hasClients) _header.jumpTo(_horizontal.offset);
      _syncSelectedDay();
    });
  }

  /// Al desplazarse a mano, la tira marca el primer día visible (si el marcado
  /// ya no se ve).
  void _syncSelectedDay() {
    final g = _geometry;
    if (g == null || _jumpingToDay || !_horizontal.hasClients) return;
    final offset = _horizontal.offset;
    final viewport = _horizontal.position.viewportDimension;
    final first = (offset / g.dayWidth).round().clamp(0, 6);
    final last = ((offset + viewport) / g.dayWidth).round().clamp(1, 7) - 1;
    if (_selectedDay >= first && _selectedDay <= last) return;
    setState(() => _selectedDay = first);
  }

  /// Toque en la tira: lleva la columna de ese día al principio de la vista.
  Future<void> _goToDay(int day) async {
    final g = _geometry;
    setState(() => _selectedDay = day);
    if (g == null || !_horizontal.hasClients) return;
    final target = g
        .dayLeft(day)
        .clamp(0.0, _horizontal.position.maxScrollExtent);
    _jumpingToDay = true;
    try {
      if (context.reduceMotion) {
        _horizontal.jumpTo(target);
      } else {
        await _horizontal.animateTo(
          target,
          duration: context.motion(TokensDuration.normal),
          curve: Curves.easeOutCubic,
        );
      }
    } finally {
      _jumpingToDay = false;
    }
  }

  /// Avisa a la página del día visible (después del dibujo: no se cambia el
  /// estado de otro widget mientras se construye este).
  void _report(int? day) {
    final onChanged = widget.onVisibleDayChanged;
    if (onChanged == null || (_reported && _reportedDay == day)) return;
    _reported = true;
    _reportedDay = day;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onChanged(day);
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

  /// Sin eventos en el día que se abre, la vista empieza por la mañana.
  static const _morningMinutes = 7 * 60;

  /// Margen por encima de lo que se enseña al abrir.
  static const _leadMinutes = 60;

  /// Día que se abre: el del bloque pedido, el pedido, hoy (si cae en esta
  /// semana) o el lunes.
  int _initialDay(WeekGridGeometry g) =>
      g.dayIndexOf(
        widget.focusAt ?? widget.focusDay ?? widget.now,
        widget.weekStart,
      ) ??
      0;

  /// Minuto en que se coloca la vista al abrir: una hora antes del bloque
  /// pedido o, hoy, de ahora (sin tope: a las 2:00 se ve la madrugada); otro
  /// día, una hora antes de su primer evento y, sin eventos, por la mañana.
  int _initialMinutes(WeekGridGeometry g, int day) {
    final focus = widget.focusAt;
    if (focus != null) {
      return WeekGridGeometry.minutesOfDay(focus) - _leadMinutes;
    }
    if (g.dayIndexOf(widget.now, widget.weekStart) == day) {
      return WeekGridGeometry.minutesOfDay(widget.now) - _leadMinutes;
    }
    final starts = [
      for (final b in widget.blocks)
        for (final p in g.dayParts((
          start: b.start,
          end: b.end,
        ), widget.weekStart))
          if (p.day == day) WeekGridGeometry.minutesOfDay(p.part.start),
    ];
    if (starts.isEmpty) return _morningMinutes;
    return starts.reduce(math.min) - _leadMinutes;
  }

  /// Al abrir la semana se coloca en el día que toca ([_initialDay]) como
  /// primera columna visible (los anteriores quedan a la izquierda, a un toque
  /// en la tira) y a su hora ([_initialMinutes]).
  void _scrollInitially(WeekGridGeometry g) {
    if (_initialScrollDone) return;
    _initialScrollDone = true;
    final day = _initialDay(g);
    _selectedDay = day;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_vertical.hasClients) {
        _vertical.jumpTo(
          g
              .minutesToY(math.max(0, _initialMinutes(g, day)))
              .clamp(0.0, _vertical.position.maxScrollExtent),
        );
      }
      if (_horizontal.hasClients) {
        _jumpingToDay = true;
        _horizontal.jumpTo(
          g.dayLeft(day).clamp(0.0, _horizontal.position.maxScrollExtent),
        );
        _jumpingToDay = false;
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
        // Con el texto grande, las horas («10:00») y los días («dom 16»)
        // necesitan más sitio: el eje y la cabecera crecen con el texto
        // (hasta el doble) en vez de cortarlos.
        final axisWidth = math.min(
          context.scaled(WeekCanvas.axisWidth),
          WeekCanvas.axisWidth * 2,
        );
        final available = constraints.maxWidth - axisWidth;
        // Si los 7 días no caben, cada uno conserva su ancho mínimo y la tira
        // de arriba lleva a cualquiera.
        final narrow = available / 7 < WeekCanvas.minDayWidth;
        final baseHeader = narrow
            ? WeekCanvas.compactHeaderHeight
            : WeekCanvas.headerHeight;
        final headerHeight = math.min(
          context.scaled(baseHeader),
          baseHeader * 2,
        );
        final geometry = WeekGridGeometry(
          dayWidth: math.max(available / 7, WeekCanvas.minDayWidth),
          hourHeight: WeekCanvas.hourHeight,
        );
        _geometry = geometry;
        _scrollInitially(geometry);
        _report(narrow ? _selectedDay : null);
        return Column(
          children: [
            if (narrow)
              _WeekDayStrip(
                weekStart: widget.weekStart,
                now: widget.now,
                selected: _selectedDay,
                onSelected: _goToDay,
              ),
            ?widget.summary,
            SizedBox(
              height: headerHeight,
              child: Row(
                children: [
                  SizedBox(width: axisWidth),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _header,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: _DayHeader(
                        geometry: geometry,
                        weekStart: widget.weekStart,
                        now: widget.now,
                        compact: narrow,
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
                    width: axisWidth,
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

    // Tramos por día (lo que cruza la medianoche, en sus dos días),
    // repartidos en carriles si se solapan.
    final byDay = <int, List<(CalendarBlock, TimeRange, bool)>>{};
    for (final b in widget.blocks) {
      if (b.id == _activeId) {
        active = b;
        continue;
      }
      final parts = g.dayParts((start: b.start, end: b.end), widget.weekStart);
      for (final (i, p) in parts.indexed) {
        (byDay[p.day] ??= []).add((b, p.part, i == 0));
      }
    }
    for (final entry in byDay.entries) {
      final dayParts = entry.value;
      final lanes = WeekGridGeometry.assignLanes([
        for (final (_, part, _) in dayParts) part,
      ]);
      for (var i = 0; i < dayParts.length; i++) {
        final (block, part, primary) = dayParts[i];
        final extent = g.verticalExtent(part);
        if (extent == null) continue;
        final laneWidth = g.dayWidth / lanes[i].lanes;
        children.add(
          Positioned(
            key: primary
                ? ValueKey(block.id)
                : ValueKey('${block.id}@${entry.key}'),
            left: g.dayLeft(entry.key) + lanes[i].lane * laneWidth + 2,
            top: extent.top + 1,
            width: laneWidth - 4,
            height: math.max(extent.height - 2, 18),
            child: _part(
              block,
              g,
              (start: block.start, end: block.end),
              primary: primary,
              resizable: part.end == block.end,
            ),
          ),
        );
      }
    }

    // El bloque que se arrastra se pinta encima, a todo el ancho del día (y
    // en sus dos días si la vista previa cruza la medianoche). Las claves son
    // las mismas que en reposo: el tramo que se arrastra no se desmonta.
    if (active != null) {
      final range = _preview ?? (start: active.start, end: active.end);
      for (final (i, p) in g.dayParts(range, widget.weekStart).indexed) {
        final extent = g.verticalExtent(p.part);
        if (extent == null) continue;
        children.add(
          Positioned(
            key: i == 0
                ? ValueKey(active.id)
                : ValueKey('${active.id}@${p.day}'),
            left: g.dayLeft(p.day) + 2,
            top: extent.top + 1,
            width: g.dayWidth - 4,
            height: math.max(extent.height - 2, 18),
            child: _part(
              active,
              g,
              range,
              primary: i == 0,
              resizable: p.part.end == range.end,
            ),
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
                // Para el lector no es un botón: un hueco de la rejilla no se
                // puede elegir con él. Se añade con el «+», que sí lo nombra.
                excludeFromSemantics: true,
                onTapUp: (d) => widget.onSlotTap(
                  g.slotAt(
                    widget.weekStart,
                    d.localPosition.dx,
                    d.localPosition.dy,
                  ),
                ),
                onLongPressStart: widget.onSlotLongPress == null
                    ? null
                    : (d) => widget.onSlotLongPress!(
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

  /// Un tramo del bloque en un día, con el horario [shown] (el del evento
  /// entero o la vista previa). El primer tramo es el bloque: foco, lector y
  /// arrastre. El del día siguiente de algo que cruza la medianoche solo se ve
  /// y se toca (el lector y el teclado ya lo tienen en el primero). El asa de
  /// la duración ([resizable]) solo va en el tramo donde acaba el evento.
  Widget _part(
    CalendarBlock block,
    WeekGridGeometry g,
    TimeRange shown, {
    required bool primary,
    required bool resizable,
  }) {
    final tile = _tile(
      block,
      g,
      shown.start,
      shown.end,
      draggable: primary,
      resizable: resizable,
    );
    return primary
        ? _ordered(block, tile)
        : ExcludeFocus(child: ExcludeSemantics(child: tile));
  }

  Widget _tile(
    CalendarBlock block,
    WeekGridGeometry g,
    DateTime start,
    DateTime end, {
    bool draggable = true,
    bool resizable = true,
  }) {
    return TimeBlockTile(
      draggable: draggable,
      resizable: resizable,
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
    this.compact = false,
  });

  final WeekGridGeometry geometry;
  final DateTime weekStart;
  final DateTime now;

  /// Línea fina bajo la tira de días (móvil): menos relleno y letra menor.
  final bool compact;

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
          padding: EdgeInsets.symmetric(
            horizontal: TokensSpacing.s,
            vertical: compact ? TokensSpacing.xxs : TokensSpacing.xs,
          ),
          decoration: isToday
              ? BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(TokensRadius.pill),
                )
              : null,
          child: Text(
            PlannerFormats.dayShort(day),
            style:
                (compact
                        ? context.textStyles.labelMedium
                        : context.textStyles.labelLarge)
                    ?.copyWith(
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

/// Tira de los 7 días de la semana, encima del lienzo cuando no caben todos
/// (ADR 0050): lleva a cualquier día y marca el que se ve. Usa el mismo chip
/// de día que la agenda de Inicio ([AppDayChip]).
class _WeekDayStrip extends StatelessWidget {
  const _WeekDayStrip({
    required this.weekStart,
    required this.now,
    required this.selected,
    required this.onSelected,
  });

  final DateTime weekStart;
  final DateTime now;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final weekday = DateFormat.E();
    final weekdayLong = DateFormat.EEEE();
    // Margen y separación mínimos: a 360 dp cada chip llega a los 48 de toque.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.xs,
        0,
        TokensSpacing.xs,
        TokensSpacing.xs,
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: TokensSpacing.xxs),
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = PlannerWeek.dayOf(weekStart, i);
                  final isToday = PlannerWeek.isSameDay(day, now);
                  // «Lunes 16»; hoy, «Hoy, lunes 16».
                  final name = '${weekdayLong.format(day)} ${day.day}';
                  return AppDayChip(
                    // Como en la agenda de Inicio: hoy se llama «Hoy».
                    caption: isToday ? l10n.plannerToday : weekday.format(day),
                    dayNumber: day.day,
                    selected: i == selected,
                    today: isToday,
                    semanticLabel: isToday
                        ? l10n.plannerTodayDate(name)
                        : toBeginningOfSentenceCase(name),
                    onTap: () => onSelected(i),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
