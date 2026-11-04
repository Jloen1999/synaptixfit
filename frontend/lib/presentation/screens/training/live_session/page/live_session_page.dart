import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../exercise_detail/page/exercise_how_to_sheet.dart';
import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../../domain/models/training/session_adaptation.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/metric_chips.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../../widgets/set_fields.dart';
import '../../../../../domain/models/training/live_session_draft.dart';
import '../../exercise_alternatives/page/exercise_alternatives_sheet.dart';
import '../bloc/live_session_bloc.dart';
import 'live_focus_view.dart';
import 'set_record_sheet.dart';

/// Sesión de entrenamiento en vivo. Con ejercicios de rutina se entrena de uno
/// en uno ([LiveExerciseView]): cabecera con el progreso y la tira de
/// ejercicios, el ejercicio actual en grande con su tabla de series y una barra
/// inferior con la acción principal o la cuenta atrás del descanso. Las
/// sesiones libres y las ya terminadas usan la lista de series.
class LiveSessionPage extends StatelessWidget {
  const LiveSessionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<LiveSessionBloc>()..add(LiveSessionEvent.started(sessionId)),
      child: const _LiveView(),
    );
  }
}

class _LiveView extends StatefulWidget {
  const _LiveView();

  @override
  State<_LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<_LiveView> {
  Timer? _ticker;
  late final AppLifecycleListener _lifecycle;

  /// Cifras escritas en series aún sin marcar.
  final SetDrafts _drafts = {};

  /// Celdas con un valor fuera de rango (no se puede marcar su serie).
  final Set<String> _invalid = {};

  /// Se sale a propósito (pausar y salir, descartar): «atrás» ya no pregunta.
  bool _allowPop = false;

  LiveSessionBloc get _bloc => context.read<LiveSessionBloc>();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _bloc.add(const LiveSessionEvent.ticked());
    });
    // Con la app en segundo plano el temporizador se para: al volver, el
    // cronómetro y el descanso se ponen en hora al momento.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (mounted) _bloc.add(const LiveSessionEvent.resumed());
      },
    );
    // Pantalla encendida mientras se entrena (en web o escritorio sin soporte,
    // el fallo se ignora: no impide entrenar).
    unawaited(WakelockPlus.enable().catchError((Object _) {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lifecycle.dispose();
    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    super.dispose();
  }

  /// Terminar: pide el esfuerzo. Con series previstas sin hacer pregunta
  /// antes, salvo que ya se eligiera «Terminar ahora» ([confirmed]).
  Future<void> _finish(LiveSessionState state, {bool confirmed = false}) async {
    final missing = state.plannedSets - state.loggedSets;
    if (!confirmed && !state.isFree && missing > 0) {
      final l10n = context.localizations;
      final ok = await showConfirmDialog(
        context,
        title: l10n.trainingFinishEarlyTitle,
        message: l10n.trainingFinishEarlyMessage(missing),
        confirmLabel: l10n.trainingFinishAction,
      );
      if (!ok || !mounted) return;
    }
    final rpe = await showEffortDialog(
      context,
      confirmLabel: context.localizations.trainingFinishAction,
    );
    if (rpe != null && mounted) {
      _bloc.add(LiveSessionEvent.finishRequested(rpe));
    }
  }

  /// Al salir a mitad de sesión: pausar y salir, terminar ya o seguir. Lo
  /// apuntado ya está guardado; se explica en una frase.
  Future<void> _leave(LiveSessionState state) async {
    final choice = await showModalBottomSheet<_LeaveChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _LeaveSheet(
        marked: state.session?.sets.length ?? 0,
        done: state.loggedSets,
        planned: state.isFree ? 0 : state.plannedSets,
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _LeaveChoice.pause:
        _pauseAndLeave();
      case _LeaveChoice.finish:
        await _finish(_bloc.state, confirmed: true);
      case _LeaveChoice.discard:
        await _abandon();
      case _LeaveChoice.stay:
        break;
    }
  }

  /// Pausa la sesión (el tiempo deja de contar) y vuelve atrás; la barra
  /// «Sesión en pausa · Volver» la retoma.
  void _pauseAndLeave() {
    _bloc.add(const LiveSessionEvent.pauseRequested());
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  /// Sesión recién empezada: se explica que el cronómetro ya corre, que cada
  /// serie tiene el suyo (opcional) y que las pausas no cuentan.
  Future<void> _explainClock(LiveSessionState state) async {
    final result = await showModalBottomSheet<(bool, bool)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      isDismissible: false,
      builder: (_) =>
          _ClockIntroSheet(minutes: state.remainingEstimatedMinutes),
    );
    if (!mounted) return;
    final (start, hide) = result ?? (true, false);
    _bloc.add(LiveSessionEvent.clockExplained(hideNextTime: hide));
    // «Ahora no»: no se pierde nada, se pausa y se sale (descartarla sigue en
    // la hoja de salir).
    if (!start) _pauseAndLeave();
  }

  Future<void> _abandon() async {
    final l10n = context.localizations;
    final ok = await showConfirmDialog(
      context,
      title: l10n.trainingAbandonTitle,
      message: l10n.trainingAbandonMessage,
      confirmLabel: l10n.trainingAbandon,
    );
    if (ok && mounted) {
      setState(() => _allowPop = true);
      _bloc.add(const LiveSessionEvent.abandonRequested());
    }
  }

  Future<void> _editSet({
    required String title,
    required String? plannedExerciseId,
    required int setNumber,
    required ExerciseParameters? parameters,
    SessionSet? existing,
    SessionSet? previous,
    PersonalRecord? lastTime,
  }) async {
    final result = await showSetRecordSheet(
      context,
      title: title,
      existingSetId: existing?.id,
      initial: SetRecord(
        plannedExerciseId: plannedExerciseId,
        setNumber: setNumber,
        repsDone: existing?.repsDone ?? previous?.repsDone ?? parameters?.reps,
        // Sin serie anterior hoy, se propone el peso de la última sesión.
        weightKg:
            existing?.weightKg ??
            previous?.weightKg ??
            lastTime?.weightKg ??
            _plannedWeight(parameters, setNumber),
        completed: existing?.completed ?? true,
        failedReps: existing?.failedReps ?? 0,
      ),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case SetSheetSave(:final record):
        _bloc.add(LiveSessionEvent.setRecorded(record));
      case SetSheetDelete(:final setId):
        _deleteWithUndo(setId, existing);
    }
  }

  /// «Hecha»: registra la serie [setNumber] de [exercise] con los valores
  /// propuestos (los de la serie anterior, la última vez o lo previsto), sin
  /// abrir la hoja.
  void _quickLog(
    LiveSessionState state,
    PlannedExercise exercise,
    int setNumber,
  ) {
    _offerUndo(exercise, setNumber);
    final proposal = _proposal(state, exercise, setNumber);
    _bloc.add(
      LiveSessionEvent.setRecorded(
        SetRecord(
          plannedExerciseId: exercise.id,
          setNumber: setNumber,
          repsDone: proposal.reps,
          weightKg: proposal.weight,
          completed: true,
          failedReps: 0,
        ),
      ),
    );
  }

  /// «Editar» de la barra: abre la hoja de la serie que toca.
  Future<void> _editNext(
    LiveSessionState state,
    PlannedExercise exercise,
    int setNumber,
  ) => _editSet(
    title: exercise.exerciseName,
    plannedExerciseId: exercise.id,
    setNumber: setNumber,
    parameters: exercise.parameters,
    previous: state.session
        ?.setsFor(exercise.id)
        .where((s) => s.setNumber == setNumber - 1)
        .firstOrNull,
    lastTime: state.lastPerformance[exercise.exerciseId],
  );

  void _onDraft(PlannedExercise e, int set, SetField f, num? v) =>
      setState(() => _drafts[LiveSessionState.draftKey(e.id, set, f)] = v);

  void _onValidity(PlannedExercise e, int set, SetField f, bool valid) =>
      setState(() {
        final key = LiveSessionState.draftKey(e.id, set, f);
        valid ? _invalid.remove(key) : _invalid.add(key);
      });

  /// Borra la serie y ofrece «Deshacer», que la vuelve a apuntar tal cual
  /// estaba (borrar nunca es definitivo sin una segunda oportunidad).
  void _deleteWithUndo(String setId, SessionSet? before) {
    final bloc = _bloc..add(LiveSessionEvent.setDeleted(setId));
    if (before == null) return;
    final l10n = context.localizations;
    context.showUndoSnack(
      before.warmup
          ? l10n.trainingWarmupSetDeleted(before.setNumber)
          : l10n.trainingSetDeleted(before.setNumber),
      onUndo: () {
        if (bloc.isClosed) return;
        bloc.add(
          LiveSessionEvent.setRecorded(
            SetRecord(
              plannedExerciseId: before.plannedExerciseId,
              setNumber: before.setNumber,
              repsDone: before.repsDone,
              weightKg: before.weightKg,
              completed: before.completed,
              failedReps: before.failedReps,
              durationSeconds: before.durationSeconds,
              distanceMeters: before.distanceMeters,
              activeSeconds: before.activeSeconds,
              warmup: before.warmup,
              toFailure: before.toFailure,
              exerciseId: before.exerciseId,
            ),
          ),
        );
      },
      onCommit: () {},
    );
  }

  /// «Serie N registrada · Deshacer»: el aviso también lo oye el lector (el
  /// botón cambia de serie o desaparece, 4.1.3). Deshacer borra esa serie
  /// (también si aún no ha subido) y corta su descanso.
  void _offerUndo(PlannedExercise e, int set) {
    final bloc = _bloc;
    context.showUndoSnack(
      context.localizations.trainingSetLogged(set),
      onUndo: () async {
        // Mientras se guarda, el borrado se ignoraría: se espera a que acabe.
        final ready = bloc.state.saving
            ? await bloc.stream.firstWhere((s) => !s.saving)
            : bloc.state;
        final logged = ready.session
            ?.setsFor(e.id)
            .where((s) => s.setNumber == set)
            .firstOrNull;
        if (logged == null || bloc.isClosed) return;
        bloc
          ..add(LiveSessionEvent.setDeleted(logged.id))
          ..add(const LiveSessionEvent.restSkipped())
          ..add(LiveSessionEvent.exerciseSelected(e.id));
      },
      onCommit: () {},
    );
  }

  /// Marca (o vuelve a guardar) la serie [set] de [e]; lo escrito para ella
  /// deja de ser borrador.
  void _onLog(PlannedExercise e, int set, Map<SetField, num?> values) {
    final existing = _bloc.state.session
        ?.setsFor(e.id)
        .where((s) => s.setNumber == set)
        .firstOrNull;
    if (existing == null) _offerUndo(e, set);
    setState(
      () => _drafts.removeWhere((k, _) => k.startsWith('${e.id}/$set/')),
    );
    _bloc.add(
      LiveSessionEvent.setRecorded(
        setRecordFor(e, set, values, existing: existing),
      ),
    );
  }

  /// Usa (o deshace) la propuesta de carga de [e]: lo escrito a mano en sus
  /// series pendientes para esa cifra deja de mandar.
  void _onLoadToggled(PlannedExercise e, bool accepted) {
    final field = _bloc.state.loadSuggestions[e.id]?.metric.field;
    if (field == null) return;
    setState(
      () => _drafts.removeWhere(
        (k, _) => k.startsWith('${e.id}/') && k.endsWith('/${field.name}'),
      ),
    );
    _bloc.add(LiveSessionEvent.loadSuggestionToggled(e.id, accepted: accepted));
  }

  /// Serie fuera del plan: en ejercicios de repeticiones se abre la hoja para
  /// apuntarla; en los demás se marca con lo propuesto (y se corrige en la fila).
  void _onExtraSet(LiveSessionState state, PlannedExercise e, int set) {
    if (SetFields.of(e).has(SetField.reps)) {
      unawaited(
        _editSet(
          title: e.exerciseName,
          plannedExerciseId: e.id,
          setNumber: set,
          parameters: e.parameters,
          previous: state.session
              ?.setsFor(e.id)
              .where((s) => s.setNumber == set - 1)
              .firstOrNull,
          lastTime: state.lastPerformance[e.exerciseId],
        ),
      );
      return;
    }
    _onLog(e, set, state.valuesFor(e, set, _drafts));
  }

  /// «Cambiar solo hoy»: alternativas del ejercicio de la rutina; el elegido
  /// se usa en esta sesión y la rutina no cambia (ADR 0031).
  Future<void> _swap(LiveSessionState state, PlannedExercise e) async {
    final original = state.originals[e.id] ?? e;
    final bloc = _bloc;
    final chosen = await showExerciseAlternativesSheet(
      context,
      exerciseId: original.exerciseId,
      exerciseName: original.exerciseName,
      todayOnly: true,
    );
    if (chosen == null || !mounted || bloc.isClosed) return;
    bloc.add(
      LiveSessionEvent.exerciseSwapped(
        e.id,
        ExerciseSwap(
          exerciseId: chosen.id,
          name: chosen.name,
          gifUrl: chosen.gifUrl,
          previewUrl: chosen.previewUrl,
        ),
      ),
    );
    context.showSnack(context.localizations.trainingSwapTodayDone(chosen.name));
  }

  /// Apunta (o corrige) una serie de calentamiento: propone lo de la anterior
  /// de calentamiento; no cuenta como serie de trabajo.
  Future<void> _warmup(
    LiveSessionState state,
    PlannedExercise e,
    int set,
    SessionSet? existing,
  ) async {
    final previous = state.session
        ?.warmupSetsFor(e.id)
        .where((w) => w.setNumber == set - 1)
        .firstOrNull;
    final result = await showSetRecordSheet(
      context,
      title: e.exerciseName,
      existingSetId: existing?.id,
      initial: SetRecord(
        plannedExerciseId: e.id,
        setNumber: set,
        repsDone: existing?.repsDone ?? previous?.repsDone ?? e.parameters.reps,
        weightKg: existing?.weightKg ?? previous?.weightKg,
        warmup: true,
      ),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case SetSheetSave(:final record):
        _bloc.add(LiveSessionEvent.setRecorded(record));
        if (existing == null) _offerWarmupUndo(e, set);
      case SetSheetDelete(:final setId):
        _deleteWithUndo(setId, existing);
    }
  }

  /// «Calentamiento N apuntado · Deshacer», como las series de trabajo.
  void _offerWarmupUndo(PlannedExercise e, int set) {
    final bloc = _bloc;
    context.showUndoSnack(
      context.localizations.trainingWarmupSetLogged(set),
      onUndo: () async {
        final ready = bloc.state.saving
            ? await bloc.stream.firstWhere((s) => !s.saving)
            : bloc.state;
        final logged = ready.session
            ?.warmupSetsFor(e.id)
            .where((s) => s.setNumber == set)
            .firstOrNull;
        if (logged == null || bloc.isClosed) return;
        bloc.add(LiveSessionEvent.setDeleted(logged.id));
      },
      onCommit: () {},
    );
  }

  /// Sesión libre: apuntar la serie [set] (si se cronometraba, el bloc le
  /// pone su tiempo).
  Future<void> _logFree(LiveSessionState state, int set) {
    final sets = state.session?.setsFor(null) ?? const <SessionSet>[];
    return _editSet(
      title: context.localizations.trainingFreeSets,
      plannedExerciseId: null,
      setNumber: set,
      parameters: null,
      previous: sets.lastOrNull,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return MultiBlocListener(
      listeners: [
        // El descanso entre series ha llegado a cero solo (no al saltarlo): se
        // dice en texto (también al lector) y vibra si el sistema lo permite.
        BlocListener<LiveSessionBloc, LiveSessionState>(
          listenWhen: (p, c) => !p.explainClock && c.explainClock,
          listener: (context, state) => unawaited(_explainClock(state)),
        ),
        BlocListener<LiveSessionBloc, LiveSessionState>(
          listenWhen: (p, c) => c.restFinishedCount != p.restFinishedCount,
          listener: (context, state) {
            HapticFeedback.heavyImpact();
            context.showSnack(context.localizations.trainingRestOver);
          },
        ),
        // La cuenta atrás no es región viva (hablaría cada segundo): se
        // anuncia al empezar el descanso y cuando quedan 10 s.
        BlocListener<LiveSessionBloc, LiveSessionState>(
          listenWhen: (p, c) =>
              c.restRemaining != null &&
              (p.restRemaining == null ||
                  (p.restRemaining! > 10 && c.restRemaining! <= 10)),
          listener: (context, state) => SemanticsService.sendAnnouncement(
            View.of(context),
            context.localizations.trainingRestSemantics(state.restRemaining!),
            Directionality.of(context),
          ),
        ),
      ],
      child: BlocConsumer<LiveSessionBloc, LiveSessionState>(
        listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
        listener: (context, state) =>
            const TrainingEffectHandler().handle(context, state.effect!),
        builder: (context, state) {
          final title = state.dayNumber != null
              ? dayTitle(l10n, state.dayNumber!, state.dayName)
              : l10n.trainingFreeSession;
          // Salir con «atrás» a mitad de sesión pregunta qué hacer con el
          // cronómetro en vez de dejarlo corriendo sin decirlo.
          return PopScope(
            canPop:
                _allowPop ||
                state.status != LiveStatus.ready ||
                state.completed,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) unawaited(_leave(state));
            },
            child: Scaffold(
              appBar: AppPageBar(
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  // En sesión de rutina el tiempo ya está en la cabecera
                  // («4 de 6 ejercicios · 32 min»).
                  // Sesión libre en curso: el tiempo real, igual que en la de rutina.
                  if (state.status == LiveStatus.ready &&
                      state.isFree &&
                      !state.completed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TokensSpacing.xs,
                      ),
                      child: Center(
                        child: LiveClockPill(
                          seconds: state.elapsedSeconds,
                          paused: state.paused,
                        ),
                      ),
                    ),
                  if (state.status == LiveStatus.ready && state.completed)
                    Semantics(
                      label: l10n.trainingTotalTime(
                        formatClock(state.elapsedSeconds),
                      ),
                      excludeSemantics: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TokensSpacing.s,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: TokensSize.iconXs,
                              color: context.colors.secondary,
                            ),
                            const SizedBox(width: TokensSpacing.xs),
                            Text(
                              formatClock(state.elapsedSeconds),
                              style: context.textStyles.titleMedium?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (state.status == LiveStatus.ready && !state.completed)
                    IconButton(
                      tooltip: l10n.trainingLeaveExitTooltip,
                      onPressed: state.finishing ? null : () => _leave(state),
                      icon: const Icon(Icons.exit_to_app_rounded),
                    ),
                  // «Terminar» siempre a la vista y con texto, no escondido.
                  if (state.status == LiveStatus.ready &&
                      !state.completed &&
                      !state.isFree)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: TokensSpacing.s,
                      ),
                      child: FilledButton.tonal(
                        onPressed:
                            state.finishing || state.pendingSets.isNotEmpty
                            ? null
                            : () => _finish(state),
                        child: Text(l10n.trainingFinishAction),
                      ),
                    ),
                ],
              ),
              body: switch (state.status) {
                LiveStatus.loading => const AppSkeletonList(height: 140),
                LiveStatus.failure => AppErrorView(
                  error: state.error!,
                  onRetry: () => _bloc.add(
                    LiveSessionEvent.started(state.sessionId ?? ''),
                  ),
                ),
                LiveStatus.ready when state.completed || state.isFree => Column(
                  children: [
                    if (state.saving) const LinearProgressIndicator(),
                    if (state.restRemaining != null) _RestBanner(state: state),
                    Expanded(
                      child: _ExerciseList(state: state, onEdit: _editSet),
                    ),
                  ],
                ),
                LiveStatus.ready => Column(
                  children: [
                    LiveSessionHeader(state: state),
                    if (state.saving) const LinearProgressIndicator(),
                    Expanded(
                      child: LiveExerciseView(
                        state: state,
                        drafts: _drafts,
                        invalid: _invalid,
                        onDraft: _onDraft,
                        onValidity: _onValidity,
                        onLog: _onLog,
                        onLoggedTap: (e, set) =>
                            unawaited(onLoggedSetTap(context, e, set)),
                        onExtraSet: (e, set) => _onExtraSet(state, e, set),
                        onLoadToggled: _onLoadToggled,
                        onSwap: (e) => unawaited(_swap(state, e)),
                        onUnswap: (e) => _bloc.add(
                          LiveSessionEvent.exerciseSwapped(e.id, null),
                        ),
                        onWarmup: (e, set, existing) =>
                            unawaited(_warmup(state, e, set, existing)),
                        header: [
                          // Sin conexión: las series se guardan en el teléfono.
                          if (state.pendingSets.isNotEmpty) ...[
                            AppInlineMessage(
                              message: l10n.trainingOfflinePending(
                                state.pendingSets.length,
                              ),
                              tone: AppMessageTone.warning,
                            ),
                            const SizedBox(height: TokensSpacing.m),
                          ],
                          if (state.adaptation.adapted)
                            _AdaptationCard(
                              adaptation: state.adaptation,
                              exercises: state.exercises,
                              plannedSets: state.plannedSetsById,
                            ),
                          // Calentamiento al empezar; vuelta a la calma al acabar.
                          if (state.loggedSets == 0 &&
                              (state.bookends?.warmUp.isNotEmpty ?? false))
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: TokensSpacing.m,
                              ),
                              child: _BookendsCard(
                                title: l10n.trainingWarmUpTitle,
                                hint: l10n.trainingWarmUpSummary(
                                  state.bookends!.warmUp.length,
                                ),
                                icon: Icons.whatshot_rounded,
                                exercises: state.bookends!.warmUp,
                              ),
                            ),
                          if (state.upNext == null &&
                              (state.bookends?.coolDown.isNotEmpty ?? false))
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: TokensSpacing.m,
                              ),
                              child: _BookendsCard(
                                title: l10n.trainingCoolDownTitle,
                                hint: l10n.trainingCoolDownSummary(
                                  state.bookends!.coolDown.length,
                                ),
                                icon: Icons.self_improvement_rounded,
                                exercises: state.bookends!.coolDown,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              },
              bottomNavigationBar:
                  state.status != LiveStatus.ready || state.completed
                  ? null
                  : state.isFree
                  ? _BottomBar(
                      state: state,
                      onFinish: () => _finish(state),
                      onDone: (e, n) => _quickLog(state, e, n),
                      onEdit: (e, n) => _editNext(state, e, n),
                      onFreeLog: (n) => unawaited(_logFree(state, n)),
                    )
                  : LiveSessionBottomBar(
                      state: state,
                      drafts: _drafts,
                      invalid: _invalid,
                      onLog: _onLog,
                      onFinish: state.finishing || state.pendingSets.isNotEmpty
                          ? null
                          : () => _finish(state),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _RestBanner extends StatelessWidget {
  const _RestBanner({required this.state});

  final LiveSessionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    final remaining = state.restRemaining ?? 0;
    final progress = state.restTotal == 0 ? 0.0 : remaining / state.restTotal;
    return Container(
      width: double.infinity,
      color: context.colors.secondaryContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.m,
        vertical: TokensSpacing.s,
      ),
      child: TrainingContent(
        child: Row(
          children: [
            SizedBox.square(
              dimension: TokensLayout.minTouchTarget,
              child: CircularProgressIndicator(
                value: progress,
                color: context.colors.secondary,
                backgroundColor: context.colors.surface,
              ),
            ),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              // Sin región viva: se anuncia al empezar y a los 10 s (listener).
              child: Semantics(
                label: l10n.trainingRestSemantics(remaining),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trainingRest,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      formatClock(remaining),
                      style: context.textStyles.headlineSmall?.copyWith(
                        color: context.colors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.trainingRestLess,
              onPressed: () =>
                  bloc.add(const LiveSessionEvent.restAdjusted(-15)),
              icon: const Icon(Icons.remove_rounded),
            ),
            IconButton(
              tooltip: l10n.trainingRestMore,
              onPressed: () =>
                  bloc.add(const LiveSessionEvent.restAdjusted(15)),
              icon: const Icon(Icons.add_rounded),
            ),
            TextButton(
              onPressed: () => bloc.add(const LiveSessionEvent.restSkipped()),
              child: Text(l10n.trainingSkip),
            ),
          ],
        ),
      ),
    );
  }
}

/// Peso previsto para la serie [setNumber] (por serie si la rutina lo detalla).
double? _plannedWeight(ExerciseParameters? p, int setNumber) {
  final weights = p?.weightsKg;
  if (weights != null && weights.length >= setNumber) {
    return weights[setNumber - 1];
  }
  return p?.weightKg;
}

/// Valores que se proponen para la serie [setNumber] de [exercise]: los de la
/// serie anterior de hoy, los de la última vez o lo previsto.
({int reps, double? weight}) _proposal(
  LiveSessionState state,
  PlannedExercise exercise,
  int setNumber,
) {
  final previous = state.session
      ?.setsFor(exercise.id)
      .where((s) => s.setNumber == setNumber - 1)
      .firstOrNull;
  return (
    reps: previous?.repsDone ?? exercise.parameters.reps,
    weight:
        previous?.weightKg ??
        state.lastPerformance[exercise.exerciseId]?.weightKg ??
        _plannedWeight(exercise.parameters, setNumber),
  );
}

/// Barra fija de la sesión. Mientras quedan series, muestra la que toca
/// («Press banca · Serie 2 de 4 · 40 kg × 10 reps») con «Hecha» como acción
/// principal y «Finalizar» como secundaria; sin series pendientes (o en sesión
/// libre), «Finalizar» pasa a ser la principal.
class _BottomBar extends StatefulWidget {
  const _BottomBar({
    required this.state,
    required this.onFinish,
    required this.onDone,
    required this.onEdit,
    required this.onFreeLog,
  });

  final LiveSessionState state;
  final VoidCallback onFinish;
  final void Function(PlannedExercise exercise, int setNumber) onDone;
  final void Function(PlannedExercise exercise, int setNumber) onEdit;

  /// Sesión libre: apuntar la serie N (con su tiempo si se cronometraba).
  final void Function(int setNumber) onFreeLog;

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  final _doneFocus = FocusNode();
  final _finishFocus = FocusNode();

  LiveSessionState get state => widget.state;

  /// Ejercicio y serie que tocan, o nulo si ya no queda ninguna (o sesión libre).
  static (PlannedExercise, int)? _target(LiveSessionState s) {
    final up = s.isFree ? null : s.upNext;
    final next = up == null ? null : s.nextSetOf(up);
    return up == null || next == null ? null : (up, next);
  }

  @override
  void didUpdateWidget(_BottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tras la última serie «Hecha» desaparece: el foco pasa a «Finalizar» en
    // vez de perderse (2.4.3).
    if (_doneFocus.hasFocus &&
        _target(oldWidget.state) != null &&
        _target(state) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finishFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _doneFocus.dispose();
    _finishFocus.dispose();
    super.dispose();
  }

  /// Sesión libre: el mismo cronómetro por serie que en una rutina (opcional:
  /// «Apuntar serie N» siempre está a mano) y «Finalizar» aparte.
  Widget _freeControls(BuildContext context, VoidCallback? finish) {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    final sets = state.session?.setsFor(null) ?? const <SessionSet>[];
    final next = sets.fold(0, (m, x) => math.max(m, x.setNumber)) + 1;
    final timed = state.timerSet == next && state.timerExerciseId == null;
    final running = timed && state.timerSince != null;
    void resume() => bloc.add(const LiveSessionEvent.resumeRequested());
    final Widget timer = state.paused
        ? AppSecondaryButton(
            label: l10n.trainingResume,
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: resume,
          )
        : !timed
        ? AppSecondaryButton(
            label: l10n.trainingSetTimerStart,
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: next > 50
                ? null
                : () => bloc.add(LiveSessionEvent.setTimerStarted(null, next)),
          )
        : running
        ? AppSecondaryButton(
            label: l10n.trainingPause,
            icon: const Icon(Icons.pause_rounded),
            onPressed: () => bloc.add(const LiveSessionEvent.pauseRequested()),
          )
        : AppSecondaryButton(
            label: l10n.trainingResume,
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: resume,
          );
    final log = AppPrimaryButton(
      label: timed ? l10n.trainingSetDoneShort : l10n.trainingFreeLogSet(next),
      icon: Icons.check_rounded,
      focusNode: _doneFocus,
      onPressed: state.saving || next > 50 ? null : () => widget.onFreeLog(next),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                timed
                    ? (running
                          ? l10n.trainingSetRowRunning(
                              formatClock(state.timerSeconds),
                            )
                          : l10n.trainingSetRowPaused)
                    : l10n.trainingFreeSetsCount(sets.length),
                semanticsLabel: timed
                    ? (running
                          ? l10n.trainingSetTimerRunning(next)
                          : l10n.trainingSetTimerPaused(next))
                    : null,
                style: context.textStyles.labelLarge,
              ),
            ),
            TextButton.icon(
              onPressed: finish,
              focusNode: _finishFocus,
              icon: const Icon(Icons.flag_outlined),
              label: Text(l10n.trainingFinishAction),
            ),
          ],
        ),
        const SizedBox(height: TokensSpacing.s),
        if (context.largeText) ...[
          log,
          const SizedBox(height: TokensSpacing.s),
          timer,
        ] else
          Row(
            children: [
              Expanded(child: timer),
              const SizedBox(width: TokensSpacing.s),
              Expanded(flex: 2, child: log),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final target = _target(state);
    final allDone =
        state.plannedSets > 0 && state.loggedSets >= state.plannedSets;
    // Con series sin subir no se puede cerrar: se perderían.
    final finish = state.finishing || state.pendingSets.isNotEmpty
        ? null
        : widget.onFinish;
    final progress = state.isFree
        ? null
        : Text(
            allDone
                ? l10n.trainingAllSetsDone
                : l10n.trainingSetsProgress(
                    state.loggedSets,
                    state.plannedSets,
                  ),
            style: context.textStyles.labelLarge?.copyWith(
              color: allDone ? context.palette.success : null,
            ),
          );
    final Widget content;
    if (state.isFree) {
      content = _freeControls(context, finish);
    } else if (target == null) {
      content = Row(
        children: [
          if (progress != null) Expanded(child: progress) else const Spacer(),
          const SizedBox(width: TokensSpacing.s),
          AppPrimaryButton(
            label: l10n.trainingFinishAction,
            icon: Icons.flag_rounded,
            loading: state.finishing,
            focusNode: _finishFocus,
            onPressed: finish,
          ),
        ],
      );
    } else {
      final (up, next) = target;
      final proposal = _proposal(state, up, next);
      final hold = up.parameters.isometricSeconds;
      final weight = proposal.weight;
      final (load, loadSpoken) = hold != null
          ? (l10n.trainingUpNextHold(hold), l10n.trainingUpNextHoldSpoken(hold))
          : weight != null && weight > 0
          ? (
              l10n.trainingUpNextLoad(formatNumber(weight), proposal.reps),
              l10n.trainingUpNextLoadSpoken(
                formatNumber(weight),
                proposal.reps,
              ),
            )
          : (
              l10n.trainingSetReps(proposal.reps),
              l10n.trainingUpNextRepsSpoken(proposal.reps),
            );
      final setLabel = l10n.trainingUpNextSet(next, up.parameters.sets);
      // En pantallas bajas (móvil apaisado) o con letra grande se ahorra la
      // línea «Ahora toca» (el lector la sigue oyendo).
      final compact =
          MediaQuery.sizeOf(context).height < TokensLayout.compactHeight ||
          context.largeText;
      // Mientras se guarda la serie anterior los botones siguen activos (si se
      // desactivaran perderían el foco), pero el toque se ignora: la serie que
      // toca aún no se ha actualizado y se apuntaría dos veces.
      void ifIdle(void Function() action) {
        if (!state.saving) action();
      }

      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (progress != null) Expanded(child: progress),
              TextButton.icon(
                onPressed: finish,
                icon: const Icon(Icons.flag_outlined),
                label: Text(l10n.trainingFinishAction),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  label: [
                    l10n.trainingUpNextLabel,
                    up.exerciseName,
                    setLabel,
                    loadSpoken,
                  ].join(', '),
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!compact)
                        Text(
                          l10n.trainingUpNextLabel,
                          style: context.textStyles.labelMedium?.copyWith(
                            color: context.colors.secondary,
                          ),
                        ),
                      Text(
                        up.exerciseName,
                        style: context.textStyles.titleMedium,
                      ),
                      Text(
                        '$setLabel · $load',
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.trainingHowToNamed(up.exerciseName),
                onPressed: () => openHowTo(context, up),
                icon: const Icon(Icons.ondemand_video_rounded),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          Row(
            children: [
              Flexible(
                child: AppSecondaryButton(
                  label: l10n.commonEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => ifIdle(() => widget.onEdit(up, next)),
                ),
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                flex: 2,
                child: AppPrimaryButton(
                  label: l10n.trainingSetDoneAction,
                  icon: Icons.check_rounded,
                  focusNode: _doneFocus,
                  onPressed: () => ifIdle(() => widget.onDone(up, next)),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        // Con letra muy grande en una pantalla baja la barra no puede tapar la
        // lista: tiene un alto máximo y su contenido se desplaza.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height *
                TokensLayout.bottomBarMaxShare,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            child: TrainingContent(child: content),
          ),
        ),
      ),
    );
  }
}

typedef _EditSet =
    Future<void> Function({
      required String title,
      required String? plannedExerciseId,
      required int setNumber,
      required ExerciseParameters? parameters,
      SessionSet? existing,
      SessionSet? previous,
      PersonalRecord? lastTime,
    });

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.state, required this.onEdit});

  final LiveSessionState state;
  final _EditSet onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final session = state.session!;
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.completed)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.m),
                  child: AppCard(
                    color: context.colors.secondaryContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: context.colors.onSecondaryContainer,
                        ),
                        const SizedBox(width: TokensSpacing.s),
                        Expanded(
                          child: Text(
                            l10n.trainingSessionAlreadyCompleted,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Sin conexión: las series se guardan en el teléfono.
              if (state.pendingSets.isNotEmpty) ...[
                AppInlineMessage(
                  message: l10n.trainingOfflinePending(
                    state.pendingSets.length,
                  ),
                  tone: AppMessageTone.warning,
                ),
                const SizedBox(height: TokensSpacing.m),
              ],
              if (!state.completed && state.adaptation.adapted)
                _AdaptationCard(
                  adaptation: state.adaptation,
                  exercises: state.exercises,
                  plannedSets: state.plannedSetsById,
                ),
              if (state.isFree)
                _FreeSetsCard(
                  sets: session.setsFor(null),
                  readOnly: state.completed,
                  onEdit: onEdit,
                ),
              if (!state.completed &&
                  (state.bookends?.warmUp.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                  child: _BookendsCard(
                    title: l10n.trainingWarmUpTitle,
                    hint: l10n.trainingWarmUpSummary(
                      state.bookends!.warmUp.length,
                    ),
                    icon: Icons.whatshot_rounded,
                    exercises: state.bookends!.warmUp,
                  ),
                ),
              for (final e in state.exercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                  child: _ExerciseCard(
                    exercise: e,
                    lastTime: state.lastPerformance[e.exerciseId],
                    sets: session.setsFor(e.id),
                    active: state.activeExerciseId == e.id,
                    seconds: state.exerciseSeconds[e.id] ?? 0,
                    readOnly: state.completed,
                    onEdit: onEdit,
                  ),
                ),
              if (!state.completed &&
                  (state.bookends?.coolDown.isNotEmpty ?? false))
                _BookendsCard(
                  title: l10n.trainingCoolDownTitle,
                  hint: l10n.trainingCoolDownSummary(
                    state.bookends!.coolDown.length,
                  ),
                  icon: Icons.self_improvement_rounded,
                  exercises: state.bookends!.coolDown,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Calentamiento o vuelta a la calma: plegado por defecto para no distraer;
/// cada ejercicio abre su ficha con las instrucciones. Cabecera propia en vez de
/// `ExpansionTile` para que cada fila tenga su contorno de foco y se respete
/// «reducir movimiento».
class _BookendsCard extends StatefulWidget {
  const _BookendsCard({
    required this.title,
    required this.hint,
    required this.icon,
    required this.exercises,
  });

  final String title;
  final String hint;
  final IconData icon;
  final List<Exercise> exercises;

  @override
  State<_BookendsCard> createState() => _BookendsCardState();
}

class _BookendsCardState extends State<_BookendsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: AnimatedSize(
        duration: context.motion(TokensDuration.normal),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFocusOutline(
              child: Semantics(
                expanded: _expanded,
                child: ListTile(
                  leading: Icon(widget.icon, color: context.colors.secondary),
                  title: Text(
                    widget.title,
                    style: context.textStyles.titleSmall,
                  ),
                  subtitle: Text(widget.hint),
                  trailing: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: context.motion(TokensDuration.normal),
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                  onTap: () => setState(() => _expanded = !_expanded),
                ),
              ),
            ),
            if (_expanded)
              for (final e in widget.exercises)
                AppFocusOutline(
                  child: ListTile(
                    leading: ExerciseThumbnail(
                      url: e.thumbnailUrl,
                      size: TokensSize.thumbnailS,
                      icon: e.category.icon,
                    ),
                    title: Text(e.name),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    // En una hoja, como «Cómo se hace» de la sesión: apilar
                    // la ruta del ejercicio (vive dentro de la pestaña) desde
                    // esta pantalla completa dejaba una pantalla oscura.
                    onTap: () => unawaited(
                      showExerciseHowToSheet(
                        context,
                        exerciseId: e.id,
                        name: e.name,
                        gifUrl: e.gifUrl,
                        previewUrl: e.previewUrl,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    this.lastTime,
    required this.sets,
    required this.active,
    required this.seconds,
    required this.readOnly,
    required this.onEdit,
  });

  final PlannedExercise exercise;

  /// Mejor serie de la última vez que hizo este ejercicio.
  final PersonalRecord? lastTime;
  final List<SessionSet> sets;
  final bool active;
  final int seconds;
  final bool readOnly;
  final _EditSet onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    final p = exercise.parameters;
    final maxRecorded = sets.fold(0, (m, s) => math.max(m, s.setNumber));
    final rows = math.max(p.sets, maxRecorded);
    // Apuntadas por número (también con repeticiones de menos), como el bloc
    // al pasar al siguiente ejercicio.
    final done = {
      for (final s in sets)
        if (s.setNumber <= p.sets) s.setNumber,
    }.length;
    final finished = done >= p.sets;
    // Un ejercicio terminado y que no se está mirando queda en una línea; se
    // abre tocándolo (por si hay que corregir una serie).
    final compact = finished && !active && !readOnly;
    final card = AppCard(
      color: active ? context.colors.surfaceContainerLow : null,
      onTap: readOnly
          ? null
          : () => bloc.add(
              LiveSessionEvent.exerciseSelected(active ? null : exercise.id),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExerciseThumbnail(
                url: exercise.thumbnailUrl,
                size: TokensSize.thumbnailS,
              ),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: context.textStyles.titleSmall,
                    ),
                    if (lastTime != null)
                      // El lector leería «×» como «multiplicado por».
                      Semantics(
                        label: lastTime!.weightKg == null
                            ? null
                            : l10n.trainingLastTimeWeightSpoken(
                                formatNumber(lastTime!.weightKg!),
                                lastTime!.reps,
                              ),
                        excludeSemantics: lastTime!.weightKg != null,
                        child: Text(
                          lastTime!.weightKg == null
                              ? l10n.trainingLastTimeReps(lastTime!.reps)
                              : l10n.trainingLastTimeWeight(
                                  formatNumber(lastTime!.weightKg!),
                                  lastTime!.reps,
                                ),
                          style: context.textStyles.labelMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Text(
                      l10n.trainingSetsDone(done, p.sets),
                      style: context.textStyles.labelMedium?.copyWith(
                        color: done >= p.sets
                            ? context.palette.success
                            : context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!readOnly)
                Semantics(
                  label: active
                      ? l10n.trainingExerciseTimerActive(formatClock(seconds))
                      : l10n.trainingExerciseTimerPaused(formatClock(seconds)),
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      Icon(
                        active
                            ? Icons.play_circle_fill_rounded
                            : Icons.pause_circle_outline_rounded,
                        size: TokensSize.iconXs,
                        color: active
                            ? context.colors.secondary
                            : context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: TokensSpacing.xxs),
                      Text(
                        formatClock(seconds),
                        style: context.textStyles.labelLarge,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: TokensSpacing.s),
            ExerciseParameterChips(parameters: p),
            const SizedBox(height: TokensSpacing.s),
            for (var n = 1; n <= rows; n++)
              _SetRow(
                setNumber: n,
                set: sets.where((s) => s.setNumber == n).firstOrNull,
                readOnly: readOnly,
                onTap: () => onEdit(
                  title: exercise.exerciseName,
                  plannedExerciseId: exercise.id,
                  setNumber: n,
                  parameters: p,
                  existing: sets.where((s) => s.setNumber == n).firstOrNull,
                  previous: sets.where((s) => s.setNumber == n - 1).firstOrNull,
                  lastTime: lastTime,
                ),
              ),
            // La serie que toca se apunta desde la barra inferior; aquí, cómo se
            // hace (con texto, para que se descubra) y las series extra.
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowAlignment: OverflowBarAlignment.start,
              overflowSpacing: TokensSpacing.xs,
              children: [
                Semantics(
                  label: l10n.trainingHowToNamed(exercise.exerciseName),
                  button: true,
                  excludeSemantics: true,
                  onTap: () => openHowTo(context, exercise),
                  child: TextButton.icon(
                    onPressed: () => openHowTo(context, exercise),
                    icon: const Icon(Icons.ondemand_video_rounded),
                    label: Text(l10n.trainingHowTo),
                  ),
                ),
                if (!readOnly)
                  TextButton.icon(
                    onPressed: rows >= 50
                        ? null
                        : () => onEdit(
                            title: exercise.exerciseName,
                            plannedExerciseId: exercise.id,
                            setNumber: rows + 1,
                            parameters: p,
                            previous: sets
                                .where((s) => s.setNumber == rows)
                                .firstOrNull,
                          ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.trainingExtraSet),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    // Terminado y plegado: se anuncia como desplegable.
    return finished && !readOnly
        ? Semantics(expanded: !compact, child: card)
        : card;
  }
}

class _FreeSetsCard extends StatelessWidget {
  const _FreeSetsCard({
    required this.sets,
    required this.readOnly,
    required this.onEdit,
  });

  final List<SessionSet> sets;
  final bool readOnly;
  final _EditSet onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final next = sets.fold(0, (m, s) => math.max(m, s.setNumber)) + 1;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.trainingFreeSets, style: context.textStyles.titleSmall),
          Text(
            l10n.trainingFreeSetsHint,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          for (final s in sets)
            _SetRow(
              setNumber: s.setNumber,
              set: s,
              readOnly: readOnly,
              onTap: () => onEdit(
                title: l10n.trainingFreeSets,
                plannedExerciseId: null,
                setNumber: s.setNumber,
                parameters: null,
                existing: s,
              ),
            ),
          if (!readOnly)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: next > 50
                    ? null
                    : () => onEdit(
                        title: l10n.trainingFreeSets,
                        plannedExerciseId: null,
                        setNumber: next,
                        parameters: null,
                        previous: sets.lastOrNull,
                      ),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.trainingAddSet),
              ),
            ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.readOnly,
    required this.onTap,
  });

  final int setNumber;
  final SessionSet? set;
  final bool readOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = set;
    final (icon, color) = switch (s) {
      null => (Icons.radio_button_unchecked_rounded, context.colors.outline),
      SessionSet(completed: true) => (
        Icons.check_circle_rounded,
        context.palette.success,
      ),
      _ => (Icons.cancel_rounded, context.palette.warning),
    };
    final summary = s == null
        ? l10n.trainingSetPending
        : [
            if (s.repsDone != null) l10n.trainingSetReps(s.repsDone!),
            if (s.durationSeconds != null) formatClock(s.durationSeconds!),
            if (s.distanceMeters != null)
              l10n.trainingChipDistanceM(s.distanceMeters!),
            if (s.weightKg != null)
              l10n.trainingChipWeight(formatNumber(s.weightKg!)),
            if (s.failedReps > 0) l10n.trainingSetFailed(s.failedReps),
            if (!s.completed) l10n.trainingSetNotCompleted,
          ].join(' · ');
    return AppFocusOutline(
      borderRadius: BorderRadius.circular(TokensRadius.s),
      child: InkWell(
        onTap: readOnly ? null : onTap,
        borderRadius: BorderRadius.circular(TokensRadius.s),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: TokensLayout.minTouchTarget,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: TokensSize.iconM),
              const SizedBox(width: TokensSpacing.s),
              // Columna alineada entre filas que crece con el texto (200 %).
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: context.scaled(
                    TokensLayout.minTouchTarget + TokensSpacing.m,
                  ),
                ),
                child: Text(
                  l10n.trainingSetNumber(setNumber),
                  style: context.textStyles.labelLarge,
                ),
              ),
              Expanded(
                child: Text(summary, style: context.textStyles.bodyMedium),
              ),
              if (!readOnly)
                Icon(
                  s == null ? Icons.add_rounded : Icons.edit_outlined,
                  size: TokensSize.iconXs,
                  color: context.colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso de sesión adaptada (regulación cruzada): por qué hay menos series hoy.
/// «Sesión adaptada hoy»: por qué (examen, carga o fatiga, lo decide el
/// servidor), qué cambia en cada ejercicio («Press banca: 4 → 3 series»), que
/// solo es hoy (la rutina no cambia) y la opción de hacerla completa.
class _AdaptationCard extends StatelessWidget {
  const _AdaptationCard({
    required this.adaptation,
    required this.exercises,
    required this.plannedSets,
  });

  final SessionAdaptation adaptation;
  final List<PlannedExercise> exercises;
  final Map<String, int> plannedSets;

  /// La adaptación cuida de la fatiga o la carga: deshacerla se confirma.
  Future<void> _decline(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    final ok = await showConfirmDialog(
      context,
      title: l10n.trainingAdaptedDeclineTitle,
      message: l10n.trainingAdaptedDeclineMessage,
      confirmLabel: l10n.trainingAdaptedDecline,
      destructive: false,
    );
    if (ok) bloc.add(const LiveSessionEvent.adaptationDeclined());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final onColor = context.colors.onTertiaryContainer;
    final style = context.textStyles.bodyMedium?.copyWith(color: onColor);
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: Semantics(
        container: true,
        child: AppCard(
          color: context.colors.tertiaryContainer,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tune_rounded, color: onColor),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trainingAdaptedTitle,
                      style: context.textStyles.titleSmall?.copyWith(
                        color: onColor,
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    for (final reason in adaptation.reasons)
                      Text(switch (reason) {
                        SessionAdaptationReason.examSoon =>
                          l10n.trainingAdaptedExam,
                        SessionAdaptationReason.overtraining =>
                          l10n.trainingAdaptedOvertraining,
                        SessionAdaptationReason.highFatigue =>
                          l10n.trainingAdaptedFatigue,
                      }, style: style),
                    Text(
                      l10n.trainingAdaptedSets(
                        (adaptation.volumeFactor * 100).round(),
                      ),
                      style: style,
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    for (final e in exercises)
                      if ((plannedSets[e.id] ?? e.parameters.sets) !=
                          e.parameters.sets)
                        Text(
                          l10n.trainingAdaptedExercise(
                            e.exerciseName,
                            plannedSets[e.id]!,
                            e.parameters.sets,
                          ),
                          style: style,
                        ),
                    const SizedBox(height: TokensSpacing.xs),
                    Text(l10n.trainingAdaptedScope, style: style),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        style: TextButton.styleFrom(foregroundColor: onColor),
                        onPressed: () => _decline(context),
                        child: Text(l10n.trainingAdaptedDecline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _LeaveChoice { pause, finish, stay, discard }

/// Hoja «¿Salir sin terminar?»: cada opción dice en una línea qué pasa, con
/// las series marcadas ([marked]) y, en una rutina, cuántas de las previstas
/// ([done] de [planned]; 0 en sesión libre).
class _LeaveSheet extends StatelessWidget {
  const _LeaveSheet({
    required this.marked,
    required this.done,
    required this.planned,
  });

  final int marked;
  final int done;
  final int planned;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    Widget option(
      _LeaveChoice choice,
      String label,
      String hint, {
      required bool primary,
    }) {
      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textStyles.titleSmall?.copyWith(
              color: primary ? context.colors.onPrimary : null,
            ),
          ),
          Text(
            hint,
            style: context.textStyles.bodySmall?.copyWith(
              color: primary
                  ? context.colors.onPrimary
                  : context.colors.onSurfaceVariant,
            ),
          ),
        ],
      );
      final child = Padding(
        padding: const EdgeInsets.symmetric(vertical: TokensSpacing.s),
        child: Align(alignment: AlignmentDirectional.centerStart, child: text),
      );
      return primary
          ? FilledButton(
              onPressed: () => Navigator.of(context).pop(choice),
              child: child,
            )
          : OutlinedButton(
              onPressed: () => Navigator.of(context).pop(choice),
              child: child,
            );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.l,
          0,
          TokensSpacing.l,
          TokensSpacing.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.trainingLeaveTitle,
                style: context.textStyles.titleLarge,
              ),
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(l10n.trainingLeaveMessage(marked)),
            const SizedBox(height: TokensSpacing.m),
            option(
              _LeaveChoice.pause,
              l10n.trainingLeavePause,
              l10n.trainingLeavePauseHint,
              primary: true,
            ),
            const SizedBox(height: TokensSpacing.s),
            option(
              _LeaveChoice.finish,
              l10n.trainingLeaveFinish,
              planned > 0
                  ? l10n.trainingLeaveFinishHintCount(done, planned)
                  : l10n.trainingLeaveFinishHint,
              primary: false,
            ),
            const SizedBox(height: TokensSpacing.xs),
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(_LeaveChoice.stay),
              child: Text(l10n.trainingLeaveStay),
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.trainingLeaveStale,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: context.colors.error,
              ),
              onPressed: () => Navigator.of(context).pop(_LeaveChoice.discard),
              child: Text(l10n.trainingLeaveDiscard),
            ),
          ],
        ),
      ),
    );
  }
}

/// Explicación del cronómetro al empezar: devuelve (empezar, no volver a
/// explicarlo).
class _ClockIntroSheet extends StatefulWidget {
  const _ClockIntroSheet({required this.minutes});

  final int? minutes;

  @override
  State<_ClockIntroSheet> createState() => _ClockIntroSheetState();
}

class _ClockIntroSheetState extends State<_ClockIntroSheet> {
  bool _hide = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    Widget point(int n, String text) => Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStepBadge(number: n),
          const SizedBox(width: TokensSpacing.s),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.l,
          0,
          TokensSpacing.l,
          TokensSpacing.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.trainingClockIntroTitle,
                style: context.textStyles.titleLarge,
              ),
            ),
            if (widget.minutes case final m? when m > 0) ...[
              const SizedBox(height: TokensSpacing.s),
              Align(
                alignment: AlignmentDirectional.centerStart,
                // Neutra: es una estimación (el naranja es el tiempo real).
                child: AppPill(
                  label: l10n.trainingClockIntroEstimate(m),
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
            const SizedBox(height: TokensSpacing.m),
            point(1, l10n.trainingClockIntroPoint1),
            point(2, l10n.trainingClockIntroPoint2),
            point(3, l10n.trainingClockIntroPoint3),
            AppFocusOutline(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _hide,
                onChanged: (v) => setState(() => _hide = v ?? false),
                title: Text(l10n.trainingClockIntroHide),
              ),
            ),
            const SizedBox(height: TokensSpacing.s),
            AppPrimaryButton(
              label: l10n.trainingClockIntroStart,
              // El cronómetro ya corre: el botón confirma, no arranca nada.
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(context).pop((true, _hide)),
            ),
            const SizedBox(height: TokensSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop((false, _hide)),
              child: Text(l10n.trainingClockIntroNotYet),
            ),
          ],
        ),
      ),
    );
  }
}
