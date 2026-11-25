import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/guide_id.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/planner/calendar_block.dart';
import '../../../../../domain/models/planner/planner_week.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../../shell/widgets/first_time_guide.dart';
import '../../block_editor/bloc/block_editor_bloc.dart';
import '../../block_editor/page/block_editor_sheet.dart';
import '../../planner_routes.dart';
import '../../weekly_load/page/weekly_load_sheet.dart';
import '../../widgets/planner_visuals.dart';
import '../../widgets/week_canvas.dart';
import '../../widgets/week_overview.dart';
import '../bloc/calendar_bloc.dart';
import 'block_details_sheet.dart';

/// Pestaña Calendario (`/planner`): la semana con sus eventos. Los parámetros
/// llegan del enlace (avisos, Inicio, «Tu semana»); la ruta la recrea con una
/// clave por consulta, así que un enlace nuevo vuelve a abrir lo pedido.
class CalendarPage extends StatelessWidget {
  const CalendarPage({
    super.key,
    this.initialWeek,
    this.initialBlockId,
    this.initialDay,
    this.initialCreate = false,
  });

  /// Abre «Añadir al calendario» en el próximo hueco al cargar (un toque desde
  /// «Tu día» de Inicio).
  final bool initialCreate;

  /// Cualquier día de la semana que se abre (la actual si es nulo).
  final DateTime? initialWeek;

  /// Bloque que se enseña al abrir (se centra en él y se abre su ficha).
  final String? initialBlockId;

  /// Día en que se coloca el lienzo al abrir (p. ej. desde «Tu semana» de
  /// Inicio); sin bloque pedido, se centra en su mañana.
  final DateTime? initialDay;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CalendarBloc>()..add(CalendarEvent.started(week: initialWeek)),
      child: _CalendarView(
        initialBlockId: initialBlockId,
        initialDay: initialDay,
        initialCreate: initialCreate,
      ),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView({
    this.initialBlockId,
    this.initialDay,
    this.initialCreate = false,
  });

  final String? initialBlockId;
  final DateTime? initialDay;
  final bool initialCreate;

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> with ErrorsMessageMixin {
  DateTime _now = DateTime.now();

  /// Sube con cada «Hoy» para recrear el lienzo y centrarlo de nuevo en hoy.
  int _todayTick = 0;

  /// Vuelve a colocar la vista en hoy aunque ya sea esta semana. «Hoy»
  /// desaparece al pulsarlo: el foco pasa a la semana, que se anuncia
  /// (WCAG 2.4.3).
  void _goToday() {
    setState(() {
      _todayTick++;
      // Tras «Hoy» el lienzo se centra en ahora, no en el bloque pedido.
      _focusDone = true;
    });
    _bloc.add(const CalendarEvent.todayRequested());
    AppFocusAnchor.focusSoon(_weekFocus);
  }

  /// Rango de la semana: recibe el foco tras «Hoy».
  final _weekFocus = FocusNode(debugLabel: 'planner-week');

  /// Partes que señala la guía la primera vez (ADR 0049 y 0060).
  final _addKey = GlobalKey(debugLabel: 'guide-calendar-add');
  final _weekKey = GlobalKey(debugLabel: 'guide-calendar-week');
  final _summaryKey = GlobalKey(debugLabel: 'guide-calendar-summary');
  final _deadlinesKey = GlobalKey(debugLabel: 'guide-calendar-deadlines');

  List<AppGuideStep> _guideSteps(BuildContext context) {
    final l10n = context.localizations;
    return [
      AppGuideStep(
        target: _addKey,
        title: l10n.guideCalendarAddTitle,
        body: l10n.guideCalendarAddBody,
      ),
      AppGuideStep(
        target: _weekKey,
        title: l10n.guideCalendarDoneTitle,
        body: l10n.guideCalendarDoneBody,
      ),
      // Mover y alargar va en la guía (una vez por cuenta y teléfono), no en
      // un aviso que se repetía cada vez que se abría la página.
      AppGuideStep(
        target: _weekKey,
        title: l10n.guideCalendarMoveTitle,
        body: l10n.guideCalendarMoveBody,
      ),
      AppGuideStep(
        target: _summaryKey,
        title: l10n.guideCalendarSummaryTitle,
        body: l10n.guideCalendarSummaryBody,
      ),
      AppGuideStep(
        target: _deadlinesKey,
        title: l10n.guideCalendarDeadlinesTitle,
        body: l10n.guideCalendarDeadlinesBody,
      ),
    ];
  }

  /// «Hoy» solo fuera de la semana actual (ADR 0060): dentro de ella, la tira
  /// de días ya lleva a hoy con un toque.
  bool _showToday(DateTime weekStart) =>
      !PlannerWeek.isSameDay(weekStart, PlannerWeek.mondayOf(_now));

  Timer? _clock;

  /// El bloque pedido ya se ha enseñado: el lienzo vuelve a centrarse en ahora.
  bool _focusDone = false;

  /// Último aviso mostrado: el oyente también salta al cargar la semana.
  int _lastNoticeId = 0;

  /// Bloque pedido al abrir que aún no se ha enseñado (una sola vez).
  late String? _pendingBlockId = widget.initialBlockId;

  /// «Añadir al calendario» pedido al abrir y aún no mostrado (una vez).
  late bool _pendingCreate = widget.initialCreate;

  /// Al cargar la semana por primera vez, abre la ficha del evento pedido (si
  /// sigue existiendo; el lienzo ya se ha centrado en su hora) o la hoja de
  /// crear un evento en el próximo hueco.
  void _showPendingBlock(CalendarState state) {
    if (_pendingCreate && state.status == CalendarStatus.ready) {
      // Con estado: la guía (ADR 0049) espera a que se haya enseñado.
      setState(() => _pendingCreate = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_openEditor(start: _nextSlot(state.weekStart)));
      });
      return;
    }
    final id = _pendingBlockId;
    if (id == null || state.status != CalendarStatus.ready) return;
    setState(() => _pendingBlockId = null);
    final block = state.blocks.where((b) => b.id == id).firstOrNull;
    if (block == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_openDetails(block));
    });
  }

  @override
  void initState() {
    super.initState();
    // Refresca la línea de «ahora» y la zona pasada cada minuto.
    _clock = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _weekFocus.dispose();
    super.dispose();
  }

  CalendarBloc get _bloc => context.read<CalendarBloc>();

  void _updateAccount(Account? account) {
    if (account != null) {
      context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
    }
  }

  /// Ficha de lectura del evento tocado (ADR 0060). Un examen o una entrega
  /// del calendario son la entrega misma (ADR 0039): se abre esa entrega.
  Future<void> _openDetails(CalendarBlock block) async {
    final deadlineId = block.deadlineId;
    if (block.type.createsDeadline && deadlineId != null) {
      await context.push<void>(PlannerPaths.deadline(deadlineId));
      _bloc.add(const CalendarEvent.refreshed());
      return;
    }
    final bloc = _bloc;
    final action = await BlockDetailsSheet.show(
      context,
      // Con los datos del momento: si el evento cambia (se marca, llega el
      // nombre del reto) la ficha se repinta.
      builder: (_, pick) => BlocBuilder<CalendarBloc, CalendarState>(
        bloc: bloc,
        builder: (context, state) {
          final current =
              state.blocks.where((b) => b.id == block.id).firstOrNull ?? block;
          return BlockDetailsSheet(
            details: BlockDetails(
              block: current,
              title: _titleOf(state, current),
              subjectName: state.blockSubjects[current.id],
              challenge: state.challengeOf(current),
              busy:
                  state.busyBlockIds.contains(current.id) ||
                  state.startingTraining,
            ),
            now: DateTime.now(),
            onAction: pick,
          );
        },
      ),
    );
    if (!mounted || action == null) return;
    await _runDetailsAction(action, block);
  }

  /// Lo que se pidió en la ficha, con los casos de uso del bloc o navegando.
  Future<void> _runDetailsAction(
    BlockDetailsAction action,
    CalendarBlock block,
  ) async {
    switch (action) {
      case BlockDetailsAction.focus:
        unawaited(
          context.push<void>(
            PlannerPaths.pomodoroFor(
              blockId: block.id,
              subjectId: block.subjectId,
              title: _titleOf(_bloc.state, block),
            ),
          ),
        );
      case BlockDetailsAction.startTraining:
        _bloc.add(CalendarEvent.trainingStartRequested(block.id));
      case BlockDetailsAction.openRoutine:
        // La rutina vive en la pestaña Entreno: se cambia de pestaña (nunca se
        // apila una ruta de pestaña).
        final routineId = block.routineId;
        if (routineId != null) {
          context.go(PlannerExternalPaths.routine(routineId));
        }
      case BlockDetailsAction.toggleDone || BlockDetailsAction.classWent:
        await _toggleCompletion(block.id);
      case BlockDetailsAction.classAbsent:
        _bloc.add(CalendarEvent.completionToggled(block.id, completed: false));
      case BlockDetailsAction.move:
        await _moveToDay(block);
      case BlockDetailsAction.delete:
        _bloc.add(CalendarEvent.blockDeleteRequested(block));
      case BlockDetailsAction.edit:
        await _openEditor(block: block);
      case BlockDetailsAction.openSubject:
        final subjectId = block.subjectId;
        if (subjectId == null) return;
        await context.push<void>(PlannerExternalPaths.subject(subjectId));
        _bloc.add(const CalendarEvent.refreshed());
      case BlockDetailsAction.goToClass:
        final link = block.onlineLink;
        var opened = false;
        // Sin app que lo abra, `launchUrl` lanza `PlatformException` en vez
        // de devolver falso: se trata igual, con su aviso.
        try {
          opened =
              link != null &&
              await launchUrl(link, mode: LaunchMode.externalApplication);
        } catch (_) {
          opened = false;
        }
        if (!opened && mounted) {
          context.showSnack(context.localizations.plannerDetailsLinkFailed);
        }
    }
  }

  /// «Pasar a otro día»: el mismo selector que Inicio (misma hora, ADR 0059).
  Future<void> _moveToDay(CalendarBlock block) async {
    final day = await showMoveDaySheet(
      context,
      from: block.start,
      now: DateTime.now(),
    );
    if (day == null || !mounted) return;
    final start = DateTime(
      day.year,
      day.month,
      day.day,
      block.start.hour,
      block.start.minute,
    );
    _bloc.add(
      CalendarEvent.blockMoved(
        blockId: block.id,
        start: start,
        end: start.add(block.duration),
      ),
    );
  }

  /// Nombre del evento como en la rejilla (asignatura, título o su tipo).
  String _titleOf(CalendarState state, CalendarBlock block) {
    final topics = block.topics?.trim() ?? '';
    return state.blockTitles[block.id] ??
        (topics.isNotEmpty ? topics : block.type.label(context));
  }

  /// Formulario de crear (en [start]) o de editar [block] («Editar» de la
  /// ficha). Lo que devuelve se resuelve aquí.
  Future<void> _openEditor({CalendarBlock? block, DateTime? start}) async {
    final outcome = await BlockEditorSheet.show(
      context,
      block: block,
      start: start,
    );
    if (!mounted || outcome == null) return;
    final l10n = context.localizations;
    switch (outcome) {
      case BlockEditorCreated(:final overlaps, :final weeklyCopies):
        // Con copias se dice cuántas; los solapes ya los avisa la franja de
        // «solapes esta semana».
        context.showSnack(
          weeklyCopies > 0
              ? l10n.plannerBlockCreatedRepeated(weeklyCopies + 1)
              : overlaps > 0
              ? l10n.plannerOverlapWarning(overlaps)
              : l10n.plannerBlockCreated,
        );
      case BlockEditorUpdated():
        context.showSnack(l10n.plannerBlockUpdated);
      case BlockEditorDistributed(:final count):
        context.showSnack(l10n.plannerRoutineDistributed(count));
      case BlockEditorDeadlineRequested(
        :final exam,
        :final due,
        :final subjectId,
      ):
        await context.push<void>(
          PlannerPaths.newDeadline(subjectId: subjectId, exam: exam, due: due),
        );
    }
    _bloc.add(const CalendarEvent.refreshed());
  }

  /// Al marcar hecho un bloque que registra carga física (lo dice el
  /// servidor) se pregunta el esfuerzo: con él se calcula su carga.
  Future<void> _toggleCompletion(String blockId) async {
    final block = _bloc.state.blocks.where((b) => b.id == blockId).firstOrNull;
    int? effort;
    if (block != null && !block.completed && block.tracksPhysicalLoad) {
      effort = await showEffortDialog(
        context,
        confirmLabel: context.localizations.plannerSportDoneAction,
        subtitle: _bloc.state.blockTitles[block.id] ?? block.topics,
      );
      if (effort == null || !mounted) return;
    }
    _bloc.add(CalendarEvent.completionToggled(blockId, effort: effort));
  }

  Future<void> _openWeeklyLoad(DateTime weekStart) async {
    await WeeklyLoadSheet.show(context, weekStart);
    if (mounted) _bloc.add(const CalendarEvent.refreshed());
  }

  /// Próxima media hora libre para el botón «Nuevo bloque».
  DateTime _nextSlot(DateTime weekStart) {
    final now = DateTime.now();
    final base = weekStart.isAfter(now)
        ? DateTime(weekStart.year, weekStart.month, weekStart.day, 9)
        : now;
    final minutes = (base.minute ~/ 30 + 1) * 30;
    return DateTime(base.year, base.month, base.day, base.hour, minutes);
  }

  void _onNotice(BuildContext context, CalendarNotice notice) {
    final l10n = context.localizations;
    switch (notice) {
      // Sin «+N XP»: la XP se ve en Progreso (ADR 0038).
      case CalendarNoticeBlockXp(
        :final completed,
        :final account,
        :final absent,
      ):
        _updateAccount(account);
        context.showSnack(
          absent
              ? l10n.plannerClassAbsent
              : completed
              ? l10n.plannerBlockCompleted
              : l10n.plannerBlockUncompleted,
        );
      case CalendarNoticeOverlaps(:final count):
        context.showSnack(l10n.plannerOverlapWarning(count));
      case CalendarNoticeBlockLocked():
        context.showSnack(l10n.plannerBlockLocked);
      case CalendarNoticeCompletedLocked():
        context.showSnack(l10n.plannerCompletedLocked);
      case CalendarNoticeInPast():
        context.showSnack(l10n.plannerInPast);
      case CalendarNoticeCreateAt(:final start):
        unawaited(_openEditor(start: start));
      case CalendarNoticeFailure(:final error):
        context.showSnack(errorMessage(context, error));
      case CalendarNoticeMoved(:final start):
        // Dice adónde fue y «Ver» lleva a ese día (puede ser otra semana).
        context.showActionSnack(
          l10n.homeMissedMoved(
            DateFormat.MMMMEEEEd(l10n.localeName).format(start),
            DateFormat.Hm(l10n.localeName).format(start),
          ),
          actionLabel: l10n.commonView,
          onAction: () {
            if (mounted) context.go(PlannerPaths.day(start));
          },
        );
      case CalendarNoticeSessionOpened(:final sessionId):
        unawaited(context.push<void>(PlannerExternalPaths.session(sessionId)));
      case CalendarNoticeBlockDeleted(:final blockId):
        final bloc = _bloc;
        // Mismo verbo que el botón: «Eliminar» → «Eliminado del calendario».
        context.showUndoSnack(
          context.localizations.plannerEventDeleted,
          onUndo: () {
            if (!bloc.isClosed) {
              bloc.add(CalendarEvent.blockDeleteUndone(blockId));
            }
          },
          // Si la pantalla ya se cerró, el bloc lo borró al cerrarse.
          onCommit: () {
            if (!bloc.isClosed) {
              bloc.add(CalendarEvent.blockDeleteCommitted(blockId));
            }
          },
        );
    }
  }

  /// Ctrl+Z: deshace el último bloque borrado y quita su aviso.
  void _undoLastDelete() {
    final last = _bloc.state.pendingDeletionIds.lastOrNull;
    if (last == null) return;
    _bloc.add(CalendarEvent.blockDeleteUndone(last));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Inicio del bloque pedido al abrir: el lienzo se coloca en su hora y su día
  /// en lugar de en «ahora».
  DateTime? _focusOf(CalendarState state) {
    final id = widget.initialBlockId;
    if (_focusDone || id == null) return null;
    return state.blocks.where((b) => b.id == id).firstOrNull?.start;
  }

  /// Día pedido al abrir sin bloque concreto (`?day=`): el lienzo se coloca
  /// en su primer evento.
  DateTime? _focusDayOf() =>
      _focusDone || widget.initialBlockId != null ? null : widget.initialDay;

  @override
  Widget build(BuildContext context) =>
      AppUndoShortcut(onUndo: _undoLastDelete, child: _content(context));

  Widget _content(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<CalendarBloc, CalendarState>(
      listenWhen: (a, b) =>
          (a.noticeId != b.noticeId && b.notice != null) ||
          ((_pendingBlockId != null || _pendingCreate) && a.status != b.status),
      listener: (context, state) {
        _showPendingBlock(state);
        final notice = state.notice;
        if (notice != null && state.noticeId != _lastNoticeId) {
          _lastNoticeId = state.noticeId;
          _onNotice(context, notice);
        }
      },
      builder: (context, state) {
        // Si se abrió para enseñar un evento o añadir uno (Inicio, un aviso),
        // la guía espera: primero va lo pedido.
        return FirstTimeGuide(
          guide: GuideId.calendar,
          ready:
              state.status == CalendarStatus.ready &&
              _pendingBlockId == null &&
              !_pendingCreate,
          steps: _guideSteps,
          child: Scaffold(
            // Sin barra de título: la fila de la semana hace de cabecera (su
            // rango es el encabezado de la pantalla para el lector) y deja la
            // altura a la rejilla (ADR 0060).
            floatingActionButton: FloatingActionButton(
              key: _addKey,
              heroTag: 'planner-add-block',
              tooltip: l10n.plannerAddBlock,
              onPressed: () => _openEditor(start: _nextSlot(state.weekStart)),
              child: const Icon(AppIcons.add),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _WeekHeader(
                    focusNode: _weekFocus,
                    weekStart: state.weekStart,
                    onShift: (o) => _bloc.add(CalendarEvent.weekShifted(o)),
                    onToday: _showToday(state.weekStart) ? _goToday : null,
                    deadlinesKey: _deadlinesKey,
                    onOpen: (path) async {
                      await context.push(path);
                      _bloc.add(const CalendarEvent.refreshed());
                    },
                  ),
                  Expanded(child: _body(context, state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, CalendarState state) {
    final l10n = context.localizations;
    switch (state.status) {
      case CalendarStatus.loading:
        return const _CalendarSkeleton();
      case CalendarStatus.failure:
        return AppErrorView(
          error: state.error!,
          onRetry: () => _bloc.add(const CalendarEvent.refreshed()),
        );
      case CalendarStatus.ready:
        final summary = Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.m,
            0,
            TokensSpacing.m,
            TokensSpacing.xxs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyedSubtree(
                key: _summaryKey,
                child: WeekSummaryChips(
                  deadlines: state.deadlines,
                  balance: state.balance,
                  conflicts: state.conflicts,
                  titleOf: (b) => _titleOf(state, b),
                  onDeadlineTap: (id) async {
                    await context.push<void>(PlannerPaths.deadline(id));
                    _bloc.add(const CalendarEvent.refreshed());
                  },
                  onAllDeadlines: () async {
                    await context.push<void>(PlannerPaths.deadlines);
                    _bloc.add(const CalendarEvent.refreshed());
                  },
                  onBalanceTap: () => _openWeeklyLoad(state.weekStart),
                  onConflictTap: _openDetails,
                ),
              ),
              if (state.visibleBlocks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                  child: Text(
                    l10n.plannerEmptyWeekHint,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        );
        return KeyedSubtree(
          key: _weekKey,
          child: RefreshIndicator(
            onRefresh: () async {
              _bloc.add(const CalendarEvent.refreshed());
              await _bloc.stream.first.timeout(
                const Duration(seconds: 10),
                onTimeout: () => _bloc.state,
              );
            },
            child: WeekCanvas(
              key: ValueKey((state.weekStart, _todayTick)),
              weekStart: state.weekStart,
              blocks: state.visibleBlocks,
              titles: state.blockTitles,
              busyIds: state.busyBlockIds,
              now: _now,
              focusAt: _focusOf(state),
              focusDay: _focusDayOf(),
              summary: summary,
              onSlotTap: (start) => _bloc.add(CalendarEvent.slotTapped(start)),
              // Mantener pulsado un hueco también añade ahí (sobre un
              // evento, la pulsación larga lo arrastra).
              onSlotLongPress: (start) =>
                  _bloc.add(CalendarEvent.slotTapped(start)),
              onBlockTap: _openDetails,
              onReschedule: (b, start, end) => _bloc.add(
                CalendarEvent.blockRescheduled(
                  blockId: b.id,
                  start: start,
                  end: end,
                ),
              ),
              onLockedBlockTouched: (b) =>
                  _bloc.add(CalendarEvent.lockedBlockTouched(b.id)),
            ),
          ),
        );
    }
  }
}

/// Cabecera compacta del calendario (ADR 0060): ‹ «17 – 23 nov» › en una sola
/// fila con «Hoy» (solo fuera de la semana actual), «Entregas y exámenes» y
/// «Concentrarme» como iconos con nombre y el ⋮ con lo ocasional. El rango es
/// el encabezado de la pantalla. Si el rango no cabe entero en esa fila (se
/// mide con el ancho real y el tamaño de texto), «Hoy» y los iconos bajan a
/// una segunda fila. En tablet y escritorio ‹ rango › van juntos, con un ancho
/// máximo, en vez de dejar las flechas en los extremos.
class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.focusNode,
    required this.weekStart,
    required this.onShift,
    required this.onOpen,
    this.onToday,
    this.deadlinesKey,
  });

  final FocusNode focusNode;
  final DateTime weekStart;
  final ValueChanged<int> onShift;

  /// Abre una pantalla del calendario (entregas, Pomodoro, las del ⋮) y, al
  /// volver, recarga la semana.
  final ValueChanged<String> onOpen;

  /// «Hoy», solo fuera de la semana actual (nulo: no sale).
  final VoidCallback? onToday;

  /// «Entregas y exámenes» lleva la clave de la guía (ADR 0049).
  final GlobalKey? deadlinesKey;

  /// Iconos de la fila: entregas, Concentrarme y el ⋮.
  static const _toolCount = 3;

  /// «17 – 23 nov» o, si la semana cambia de mes, «27 oct – 2 nov».
  static String rangeText(BuildContext context, DateTime start, DateTime end) {
    final l10n = context.localizations;
    if (start.month == end.month && start.year == end.year) {
      return l10n.plannerWeekRangeSameMonth(
        '${start.day}',
        '${end.day}',
        DateFormat.MMM(l10n.localeName).format(end),
      );
    }
    return l10n.plannerWeekRange(
      PlannerFormats.dayMonth(start),
      PlannerFormats.dayMonth(end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final end = PlannerWeek.dayOf(weekStart, 6);
    final today = onToday;
    final longDay = DateFormat.MMMMd(l10n.localeName);
    final range = rangeText(context, weekStart, end);
    final rangeStyle = context.textStyles.titleMedium;
    final week = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: TokensLayout.weekNavMaxWidth),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.plannerPrevWeek,
            onPressed: () => onShift(-1),
            icon: const Icon(AppIcons.previous),
          ),
          Expanded(
            child: AppFocusAnchor(
              focusNode: focusNode,
              // «Calendario, semana del 17 de noviembre al 23 de noviembre»:
              // nombra la pantalla (ya no hay barra de título) y la semana.
              child: Semantics(
                header: true,
                label: l10n.plannerWeekHeaderLabel(
                  l10n.plannerTitle,
                  longDay.format(weekStart),
                  longDay.format(end),
                ),
                excludeSemantics: true,
                // Sin límite de líneas: con el texto muy grande baja de línea
                // antes que cortarse.
                child: Text(
                  range,
                  textAlign: TextAlign.center,
                  style: rangeStyle,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.plannerNextWeek,
            onPressed: () => onShift(1),
            icon: const Icon(AppIcons.next),
          ),
        ],
      ),
    );
    // Texto corto y a la vista: vuelve a la semana de hoy y a ahora.
    final todayButton = today == null
        ? null
        : TextButton(onPressed: today, child: Text(l10n.plannerToday));
    final tools = <Widget>[
      IconButton(
        key: deadlinesKey,
        tooltip: l10n.plannerMenuDeadlines,
        onPressed: () => onOpen(PlannerPaths.deadlines),
        icon: const Icon(AppIcons.delivery),
      ),
      IconButton(
        tooltip: l10n.plannerFocusOnBlock,
        onPressed: () => onOpen(PlannerPaths.pomodoro),
        icon: const Icon(AppIcons.focusTimer),
      ),
      _PlannerMenu(onOpen: onOpen),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.xxs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Lo que ocupa todo menos el rango: dos flechas, «Hoy» y los iconos.
          const target = TokensLayout.minTouchTarget;
          final todayWidth = today == null
              ? 0.0
              : context.buttonWidth(
                  l10n.plannerToday,
                  TextButtonTheme.of(context).style,
                );
          final others = target * (2 + _toolCount) + todayWidth;
          final oneRow =
              context.textWidth(range, rangeStyle) + others <=
              constraints.maxWidth;
          if (oneRow) {
            return Row(
              children: [
                Expanded(child: Center(child: week)),
                ?todayButton,
                ...tools,
              ],
            );
          }
          return Column(
            children: [
              Center(child: week),
              Row(children: [?todayButton, const Spacer(), ...tools]),
            ],
          );
        },
      ),
    );
  }
}

/// Lo ocasional del calendario (sugerir un plan, estudio ya hecho, importar
/// o sincronizar), en el ⋮.
class _PlannerMenu extends StatelessWidget {
  const _PlannerMenu({required this.onOpen});

  /// Abre la pantalla elegida (al volver se recarga la semana).
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // Entregas y Pomodoro no van aquí: se usan a diario y están a la vista
    // (iconos de la cabecera, ADR 0039 y 0060). Aquí queda lo ocasional.
    final items = [
      (
        PlannerPaths.suggestions,
        AppIcons.proposal,
        l10n.plannerMenuSuggestions,
      ),
      (PlannerPaths.pastStudy, AppIcons.pastStudy, l10n.plannerMenuPastStudy),
      (
        PlannerPaths.scheduleScan,
        AppIcons.scan,
        l10n.plannerMenuScheduleImport,
      ),
      (
        PlannerPaths.calendarSync,
        AppIcons.calendarSync,
        l10n.plannerMenuCalendarSync,
      ),
    ];
    return PopupMenuButton<String>(
      tooltip: l10n.plannerMoreOptions,
      icon: const Icon(AppIcons.menu),
      onSelected: onOpen,
      itemBuilder: (_) => [
        for (final (path, icon, label) in items)
          PopupMenuItem(
            value: path,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon),
              title: Text(label),
            ),
          ),
      ],
    );
  }
}

/// Esqueleto de la semana mientras carga, con la forma de lo que viene bajo
/// la cabecera (que ya se ve): la tira de días si no caben los 7, la línea de
/// cifras y la rejilla.
class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeletonGroup(
      child: Padding(
        padding: const EdgeInsets.all(TokensSpacing.m),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // La misma cuenta que el lienzo para decidir si hay tira de días.
            final narrow =
                (constraints.maxWidth - WeekCanvas.axisWidth) / 7 <
                WeekCanvas.minDayWidth;
            return Column(
              children: [
                if (narrow) ...[
                  AppSkeleton(height: context.scaled(TokensSize.dayChipHeight)),
                  const SizedBox(height: TokensSpacing.s),
                ],
                const AppSkeleton(height: TokensLayout.minTouchTarget),
                const SizedBox(height: TokensSpacing.s),
                const Expanded(child: AppSkeleton(height: double.infinity)),
              ],
            );
          },
        ),
      ),
    );
  }
}
