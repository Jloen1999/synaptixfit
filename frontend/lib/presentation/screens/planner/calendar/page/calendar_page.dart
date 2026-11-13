import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/planner/calendar_block.dart';
import '../../../../../domain/models/planner/planner_week.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../block_editor/bloc/block_editor_bloc.dart';
import '../../block_editor/page/block_editor_sheet.dart';
import '../../planner_routes.dart';
import '../../weekly_load/page/weekly_load_sheet.dart';
import '../../widgets/planner_visuals.dart';
import '../../widgets/week_canvas.dart';
import '../../widgets/week_overview.dart';
import '../bloc/calendar_bloc.dart';

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

  /// Vuelve a colocar la vista en hoy aunque ya sea esta semana.
  void _goToday() {
    setState(() {
      _todayTick++;
      // Tras «Hoy» el lienzo se centra en ahora, no en el bloque pedido.
      _focusDone = true;
    });
    _bloc.add(const CalendarEvent.todayRequested());
  }

  static bool _compactBar(BuildContext context) =>
      MediaQuery.sizeOf(context).width < TokensLayout.twoColumnBreakpoint / 2 ||
      context.scaled(1) > 1.3;
  Timer? _clock;

  /// El consejo de arrastrar se da una vez, al cerrar un bloque sin cambios,
  /// en lugar de ocupar una línea fija encima del calendario.
  bool _dragHintShown = false;

  /// El bloque pedido ya se ha enseñado: el lienzo vuelve a centrarse en ahora.
  bool _focusDone = false;

  /// Último aviso mostrado: el oyente también salta al cargar la semana.
  int _lastNoticeId = 0;

  /// Bloque pedido al abrir que aún no se ha enseñado (una sola vez).
  late String? _pendingBlockId = widget.initialBlockId;

  /// «Añadir al calendario» pedido al abrir y aún no mostrado (una vez).
  late bool _pendingCreate = widget.initialCreate;

  /// Al cargar la semana por primera vez, abre la ficha del bloque pedido (si
  /// sigue existiendo; el lienzo ya se ha centrado en su hora) o la hoja de
  /// crear un evento en el próximo hueco.
  void _showPendingBlock(CalendarState state) {
    if (_pendingCreate && state.status == CalendarStatus.ready) {
      _pendingCreate = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_openEditor(start: _nextSlot(state.weekStart)));
      });
      return;
    }
    final id = _pendingBlockId;
    if (id == null || state.status != CalendarStatus.ready) return;
    _pendingBlockId = null;
    final block = state.blocks.where((b) => b.id == id).firstOrNull;
    if (block == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_openEditor(block: block));
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
    super.dispose();
  }

  CalendarBloc get _bloc => context.read<CalendarBloc>();

  void _updateAccount(Account? account) {
    if (account != null) {
      context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
    }
  }

  Future<void> _openEditor({CalendarBlock? block, DateTime? start}) async {
    final outcome = await BlockEditorSheet.show(
      context,
      block: block,
      start: start,
    );
    if (!mounted) return;
    final l10n = context.localizations;
    if (outcome == null) {
      if (block != null && !_dragHintShown) {
        _dragHintShown = true;
        context.showSnack(l10n.plannerDragHint);
      }
      return;
    }
    switch (outcome) {
      case BlockEditorFocusRequested(block: final focusBlock):
        unawaited(
          context.push<void>(
            PlannerPaths.pomodoroFor(
              blockId: focusBlock.id,
              subjectId: focusBlock.subjectId,
              title:
                  _bloc.state.blockTitles[focusBlock.id] ?? focusBlock.topics,
            ),
          ),
        );
        return;
      case BlockEditorRescheduleRequested(:final blockId):
        _bloc.add(CalendarEvent.rescheduleNextRequested(blockId));
        return;
      case BlockEditorCompletionRequested(:final blockId):
        await _toggleCompletion(blockId);
      case BlockEditorAbsenceRequested(:final blockId):
        _bloc.add(CalendarEvent.completionToggled(blockId, completed: false));
        return;
      case BlockEditorTrainingRequested(:final routineId):
        // La rutina vive en la pestaña Entreno: se cambia de pestaña (nunca se
        // apila una ruta de pestaña).
        context.go(PlannerExternalPaths.routine(routineId));
        return;
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
      case BlockEditorDeleteRequested(:final block):
        _bloc.add(CalendarEvent.blockDeleteRequested(block));
        return;
      case BlockEditorDistributed(:final count):
        context.showSnack(l10n.plannerRoutineDistributed(count));
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
      case CalendarNoticeRescheduled(:final start):
        context.showSnack(
          context.localizations.plannerRescheduledTo(
            PlannerFormats.dateTime(start),
          ),
        );
      case CalendarNoticeBlockDeleted(:final blockId):
        final bloc = _bloc;
        context.showUndoSnack(
          context.localizations.plannerBlockDeleted,
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
    if (_focusDone) return null;
    final id = widget.initialBlockId;
    final day = widget.initialDay;
    if (id == null) {
      return day == null
          ? null
          : DateTime(day.year, day.month, day.day, _dayFocusHour);
    }
    return state.blocks.where((b) => b.id == id).firstOrNull?.start;
  }

  /// Hora en que se coloca el lienzo al abrir un día sin bloque concreto.
  static const _dayFocusHour = 8;

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
        return Scaffold(
          appBar: AppPageBar(
            title: Text(l10n.plannerTitle),
            actions: [
              // Con poco ancho o texto grande, «Hoy» es un icono (con nombre)
              // para que el título y el resto de acciones quepan.
              if (_compactBar(context))
                IconButton(
                  tooltip: l10n.plannerToday,
                  icon: const Icon(AppIcons.today),
                  onPressed: _goToday,
                )
              else
                TextButton(onPressed: _goToday, child: Text(l10n.plannerToday)),
              _PlannerMenu(
                onReturn: () => _bloc.add(const CalendarEvent.refreshed()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'planner-add-block',
            onPressed: () => _openEditor(start: _nextSlot(state.weekStart)),
            icon: const Icon(AppIcons.add),
            label: Text(l10n.plannerAddBlock),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _WeekNavigator(
                  weekStart: state.weekStart,
                  onShift: (o) => _bloc.add(CalendarEvent.weekShifted(o)),
                ),
                Expanded(child: _body(context, state)),
              ],
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
        String titleOf(CalendarBlock b) =>
            state.blockTitles[b.id] ?? b.type.label(context);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.m,
                0,
                TokensSpacing.m,
                TokensSpacing.s,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WeekBalanceStrip(
                    balance: state.balance,
                    onTap: () => _openWeeklyLoad(state.weekStart),
                  ),
                  if (state.conflicts.isNotEmpty) ...[
                    const SizedBox(height: TokensSpacing.s),
                    ConflictBanner(
                      conflicts: state.conflicts,
                      titleOf: titleOf,
                      onBlockTap: (b) => _openEditor(block: b),
                    ),
                  ],
                  if (state.deadlines.isNotEmpty) ...[
                    const SizedBox(height: TokensSpacing.s),
                    WeekDeadlinesStrip(
                      deadlines: state.deadlines,
                      onTap: () => context.push(PlannerPaths.deadlines),
                    ),
                  ],
                  if (state.visibleBlocks.isEmpty) ...[
                    const SizedBox(height: TokensSpacing.s),
                    Text(
                      l10n.plannerEmptyWeekHint,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
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
                  onSlotTap: (start) =>
                      _bloc.add(CalendarEvent.slotTapped(start)),
                  onBlockTap: (b) => _openEditor(block: b),
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
            ),
          ],
        );
    }
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({required this.weekStart, required this.onShift});

  final DateTime weekStart;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final end = PlannerWeek.dayOf(weekStart, 6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.s),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.plannerPrevWeek,
            onPressed: () => onShift(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              l10n.plannerWeekRange(
                PlannerFormats.dayMonth(weekStart),
                PlannerFormats.dayMonth(end),
              ),
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium,
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
  }
}

/// Accesos a las demás pantallas del planificador.
class _PlannerMenu extends StatelessWidget {
  const _PlannerMenu({required this.onReturn});

  /// Al volver de otra pantalla se recarga la semana.
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final items = [
      (
        PlannerPaths.deadlines,
        Icons.event_note_rounded,
        l10n.plannerMenuDeadlines,
      ),
      (
        PlannerPaths.suggestions,
        AppIcons.proposal,
        l10n.plannerMenuSuggestions,
      ),
      (PlannerPaths.pomodoro, AppIcons.focusTimer, l10n.plannerMenuPomodoro),
      (
        PlannerPaths.pastStudy,
        Icons.history_edu_rounded,
        l10n.plannerMenuPastStudy,
      ),
      (
        PlannerPaths.scheduleScan,
        Icons.document_scanner_rounded,
        l10n.plannerMenuScheduleImport,
      ),
      (
        PlannerPaths.calendarSync,
        Icons.cloud_sync_rounded,
        l10n.plannerMenuCalendarSync,
      ),
    ];
    return PopupMenuButton<String>(
      tooltip: l10n.plannerMoreOptions,
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (path) async {
        await context.push(path);
        onReturn();
      },
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

class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonGroup(
      child: Padding(
        padding: EdgeInsets.all(TokensSpacing.m),
        child: Column(
          children: [
            AppSkeleton(height: 44),
            SizedBox(height: TokensSpacing.m),
            Expanded(child: AppSkeleton(height: double.infinity)),
          ],
        ),
      ),
    );
  }
}
