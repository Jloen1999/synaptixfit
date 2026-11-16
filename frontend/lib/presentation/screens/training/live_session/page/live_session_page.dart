import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../exercise_detail/page/exercise_how_to_sheet.dart';
import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/guide_id.dart';
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
import '../../../social/together/widgets/workout_together_progress.dart';
import '../../../shell/widgets/first_time_guide.dart';
import 'finish_session_sheet.dart';
import 'live_focus_view.dart';
import 'set_record_sheet.dart';
import '../../training_routes.dart';

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
      // Entreno juntos (ADR 0047): la pausa del grupo llega del servidor.
      child: WorkoutTogetherLiveScope(
        sessionId: sessionId,
        onGroupPauseChanged: (context, pausedBy) => context
            .read<LiveSessionBloc>()
            .add(LiveSessionEvent.groupPauseChanged(pausedBy: pausedBy)),
        child: const _LiveView(),
      ),
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

  /// Partes que señala la guía la primera vez (ADR 0049).
  final _guide = LiveGuideKeys();

  List<AppGuideStep> _guideSteps(BuildContext context) {
    final l10n = context.localizations;
    return [
      AppGuideStep(
        target: _guide.start,
        title: l10n.guideLiveStartTitle,
        body: l10n.guideLiveStartBody,
      ),
      AppGuideStep(
        target: _guide.photo,
        title: l10n.guideLivePhotoTitle,
        body: l10n.guideLivePhotoBody,
      ),
      AppGuideStep(
        target: _guide.clock,
        title: l10n.guideLiveClockTitle,
        body: l10n.guideLiveClockBody,
      ),
      AppGuideStep(
        target: _guide.figures,
        title: l10n.guideLiveFiguresTitle,
        body: l10n.guideLiveFiguresBody,
      ),
    ];
  }

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

  /// «Terminar»: una hoja con el esfuerzo y «Guardar» (dos toques). Si faltan
  /// series o no hay ninguna, la hoja lo dice en una frase.
  Future<void> _finish(LiveSessionState state) async {
    final missing = state.isFree ? 0 : state.plannedSets - state.loggedSets;
    final rpe = await showFinishSessionSheet(
      context,
      missing: math.max(0, missing),
      empty: state.session?.sets.isEmpty ?? true,
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
        await _finish(_bloc.state);
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
      if (mounted) context.popOrGo(TrainingPaths.root);
    });
  }

  /// «Descartar sesión»: no tiene vuelta atrás, así que se confirma con el
  /// mismo verbo.
  Future<void> _abandon() async {
    final l10n = context.localizations;
    final ok = await showConfirmDialog(
      context,
      title: l10n.trainingDiscardSessionTitle,
      message: l10n.trainingDiscardSessionMessage,
      confirmLabel: l10n.trainingDiscardSession,
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
        toFailure: existing?.toFailure ?? false,
      ),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case SetSheetSave(:final record):
        _closeUnmarkNotice();
        // Corregir una serie no vuelve a empezar su descanso.
        _bloc.add(
          LiveSessionEvent.setRecorded(record, startRest: existing == null),
        );
        if (existing == null) _announceLogged(setNumber);
      case SetSheetUnmark():
        if (existing != null) _unmarkWithUndo(existing);
    }
  }

  void _onDraft(PlannedExercise e, int set, SetField f, num? v) =>
      setState(() => _drafts[LiveSessionState.draftKey(e.id, set, f)] = v);

  void _onValidity(PlannedExercise e, int set, SetField f, bool valid) =>
      setState(() {
        final key = LiveSessionState.draftKey(e.id, set, f);
        valid ? _invalid.remove(key) : _invalid.add(key);
      });

  /// Desmarca la serie al momento y ofrece «Deshacer», que la vuelve a
  /// apuntar tal cual estaba (sin diálogo: se puede deshacer). Su descanso, si
  /// es el que corre, se para (lo hace el bloc). Igual en las dos vistas.
  void _unmarkWithUndo(SessionSet before) {
    final bloc = _bloc..add(LiveSessionEvent.setDeleted(before.id));
    final l10n = context.localizations;
    _unmarkNoticeOpen = true;
    context.showUndoSnack(
      before.warmup
          ? l10n.trainingWarmupSetUnmarked(before.setNumber)
          : l10n.trainingSetUnmarked(before.setNumber),
      onUndo: () {
        _unmarkNoticeOpen = false;
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
            startRest: false,
          ),
        );
      },
      onCommit: () => _unmarkNoticeOpen = false,
    );
  }

  /// Aviso «Serie N desmarcada · Deshacer» a la vista.
  bool _unmarkNoticeOpen = false;

  /// Al volver a apuntar una serie, el aviso de desmarcar ya no vale: su
  /// «Deshacer» la apuntaría otra vez y competiría con el de la serie nueva.
  void _closeUnmarkNotice() {
    if (!_unmarkNoticeOpen) return;
    _unmarkNoticeOpen = false;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Toque en la fila de una serie hecha (fuera del ✓): la hoja para
  /// corregirla, con los campos de cómo se mide el ejercicio.
  Future<void> _correct(PlannedExercise e, SessionSet set) async {
    final result = await showSetRecordSheet(
      context,
      title: e.exerciseName,
      existingSetId: set.id,
      fields: SetFields.of(e).fields,
      initial: SetRecord(
        plannedExerciseId: e.id,
        setNumber: set.setNumber,
        repsDone: set.repsDone,
        weightKg: set.weightKg,
        durationSeconds: set.durationSeconds,
        distanceMeters: set.distanceMeters,
        activeSeconds: set.activeSeconds,
        toFailure: set.toFailure,
        exerciseId: set.exerciseId,
      ),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case SetSheetSave(:final record):
        _closeUnmarkNotice();
        _bloc.add(LiveSessionEvent.setRecorded(record, startRest: false));
      case SetSheetUnmark():
        _unmarkWithUndo(set);
    }
  }

  /// «Serie N registrada» también para el lector (el botón cambia de serie o
  /// desaparece, WCAG 4.1.3).
  void _announceLogged(int set) => SemanticsService.sendAnnouncement(
    View.of(context),
    context.localizations.trainingSetLogged(set),
    Directionality.of(context),
  );

  /// Tras marcar la serie [set] de [e]: si arranca su descanso, no hay
  /// «Deshacer» (ADR 0053: el panel del descanso va al grano; si se marcó sin
  /// querer, se quita con el ✓ verde de la fila); si no, va en el aviso.
  /// Deshacer la desmarca (también si aún no ha subido).
  void _offerUndo(PlannedExercise e, int set) {
    if (e.parameters.restSeconds > 0) {
      // Sin aviso flotante: el panel ya dice «Serie N hecha»; se dice al
      // lector una sola vez.
      _announceLogged(set);
      return;
    }
    final bloc = _bloc;
    context.showUndoSnack(
      context.localizations.trainingSetLogged(set),
      onUndo: () async {
        // Mientras se guarda, el desmarcado esperaría: se busca ya guardada.
        final ready = bloc.state.saving
            ? await bloc.stream.firstWhere((s) => !s.saving)
            : bloc.state;
        final logged = ready.session
            ?.setsFor(e.id)
            .where((s) => s.setNumber == set)
            .firstOrNull;
        if (logged == null || bloc.isClosed) return;
        bloc.add(LiveSessionEvent.setDeleted(logged.id));
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
    _closeUnmarkNotice();
    if (existing == null) _offerUndo(e, set);
    setState(
      () => _drafts.removeWhere((k, _) => k.startsWith('${e.id}/$set/')),
    );
    _bloc.add(
      LiveSessionEvent.setRecorded(
        setRecordFor(e, set, values, existing: existing),
        // Cambiar una cifra de una serie hecha no reinicia su descanso.
        startRest: existing == null,
      ),
    );
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
        _closeUnmarkNotice();
        _bloc.add(LiveSessionEvent.setRecorded(record));
        if (existing == null) _offerWarmupUndo(e, set);
      case SetSheetUnmark():
        if (existing != null) _unmarkWithUndo(existing);
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
          listenWhen: (p, c) => c.restFinishedCount != p.restFinishedCount,
          listener: (context, state) {
            HapticFeedback.heavyImpact();
            context.showSnack(context.localizations.trainingRestOver);
          },
        ),
        // Entreno juntos (ADR 0047): la pausa o la reanudación que puso otra
        // persona se dice al lector una vez, cuando la sesión ya la ha adoptado.
        BlocListener<LiveSessionBloc, LiveSessionState>(
          listenWhen: (p, c) =>
              (c.groupPausedBy != null && p.groupPausedBy == null) ||
              (p.groupPausedBy != null && p.paused && !c.paused),
          listener: (context, state) => SemanticsService.sendAnnouncement(
            View.of(context),
            state.groupPausedBy != null
                ? context.localizations.togetherPausedByAnnounce(
                    state.groupPausedBy!,
                  )
                : context.localizations.togetherResumedAnnounce,
            Directionality.of(context),
          ),
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
            // Al empezar el descanso tras la primera serie de un ejercicio
            // nuevo, también la pregunta de calibración (ADR 0054): el foco
            // va a «+15 s», debajo de ella.
            state.asksCalibrationNow && state.restRemaining! > 10
                ? context.localizations.trainingRestWithCalibrationAnnounce(
                    state.restRemaining!,
                  )
                : context.localizations.trainingRestSemantics(
                    state.restRemaining!,
                  ),
            Directionality.of(context),
          ),
        ),
        // El resultado de la calibración se anuncia una vez, cuando llega.
        BlocListener<LiveSessionBloc, LiveSessionState>(
          listenWhen: (p, c) {
            final now = c.restCalibration;
            if (now == null) return false;
            final before = p.calibrations[now.plannedExerciseId];
            final failedNow = c.calibrationFailed.contains(
              now.plannedExerciseId,
            );
            final failedBefore = p.calibrationFailed.contains(
              now.plannedExerciseId,
            );
            return (before?.step == null && now.step != null) ||
                (!failedBefore && failedNow);
          },
          listener: (context, state) => SemanticsService.sendAnnouncement(
            View.of(context),
            calibrationResultText(
              context.localizations,
              state.restCalibration!,
              failed: state.calibrationFailed.contains(
                state.restCalibration!.plannedExerciseId,
              ),
            ),
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
            // La guía, con la sesión de rutina ya cargada (la libre y la
            // terminada no tienen sus partes).
            child: FirstTimeGuide(
              guide: GuideId.liveSession,
              ready:
                  state.status == LiveStatus.ready &&
                  !state.completed &&
                  !state.isFree,
              steps: _guideSteps,
              child: Scaffold(
                appBar: AppPageBar(
                  leading: const AppBackButton(fallback: TrainingPaths.root),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  actions: [
                    // En curso, el reloj de las series y los minutos de entreno
                    // van bajo la barra (`LiveClockSummary`), igual en la sesión
                    // libre y en la de rutina; aquí solo el total al terminar.
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
                    // «Terminar» siempre a la vista y con texto, no escondido.
                    // Con todo hecho, «Terminar» ya es el botón principal de
                    // abajo: arriba no se repite.
                    if (state.status == LiveStatus.ready &&
                        !state.completed &&
                        !state.isFree &&
                        state.upNext != null)
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
                  LiveStatus.loading => const AppSkeletonList(
                    height: TokensSize.skeletonCardTall,
                  ),
                  LiveStatus.failure => AppErrorView(
                    error: state.error!,
                    onRetry: () => _bloc.add(
                      LiveSessionEvent.started(state.sessionId ?? ''),
                    ),
                  ),
                  LiveStatus.ready when state.completed || state.isFree =>
                    Column(
                      children: [
                        if (state.isFree && !state.completed)
                          Material(
                            color: context.colors.surfaceContainerLow,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: TokensSpacing.m,
                                vertical: TokensSpacing.s,
                              ),
                              child: TrainingContent(
                                child: LiveClockSummary(state: state),
                              ),
                            ),
                          ),
                        if (state.saving) const LinearProgressIndicator(),
                        Expanded(
                          child: _ExerciseList(
                            state: state,
                            onEdit: _editSet,
                            onUnmark: _unmarkWithUndo,
                          ),
                        ),
                      ],
                    ),
                  LiveStatus.ready => Column(
                    children: [
                      LiveSessionHeader(state: state, guideKeys: _guide),
                      if (state.saving) const LinearProgressIndicator(),
                      Expanded(
                        child: LiveExerciseView(
                          state: state,
                          guideKeys: _guide,
                          drafts: _drafts,
                          invalid: _invalid,
                          onDraft: _onDraft,
                          onValidity: _onValidity,
                          onLog: _onLog,
                          onUnmark: (_, set) => _unmarkWithUndo(set),
                          onCorrect: (e, set) => unawaited(_correct(e, set)),
                          onExtraSet: (e, set) => _onExtraSet(state, e, set),
                          onSwap: (e) => unawaited(_swap(state, e)),
                          onUnswap: (e) => _bloc.add(
                            LiveSessionEvent.exerciseSwapped(e.id, null),
                          ),
                          onWarmup: (e, set, existing) =>
                              unawaited(_warmup(state, e, set, existing)),
                          header: [
                            // Entrenar con amigos (ADR 0044): solo se ve si lo es.
                            const WorkoutTogetherPanel(),
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
                    ? _FreeBottomBar(
                        state: state,
                        onFinish: () => _finish(state),
                        onFreeLog: (n) => unawaited(_logFree(state, n)),
                      )
                    : LiveSessionBottomBar(
                        state: state,
                        drafts: _drafts,
                        invalid: _invalid,
                        onLog: _onLog,
                        guideKeys: _guide,
                        onFinish:
                            state.finishing || state.pendingSets.isNotEmpty
                            ? null
                            : () => _finish(state),
                      ),
              ),
            ),
          );
        },
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

/// Barra fija de la sesión libre (sin rutina): cronómetro opcional de la
/// serie, «Apuntar serie N» como acción principal y «Terminar» aparte. Con
/// rutina, la barra es `LiveSessionBottomBar`.
class _FreeBottomBar extends StatefulWidget {
  const _FreeBottomBar({
    required this.state,
    required this.onFinish,
    required this.onFreeLog,
  });

  final LiveSessionState state;
  final VoidCallback onFinish;

  /// Apuntar la serie N (con su tiempo si se cronometraba).
  final void Function(int setNumber) onFreeLog;

  @override
  State<_FreeBottomBar> createState() => _FreeBottomBarState();
}

class _FreeBottomBarState extends State<_FreeBottomBar> {
  final _doneFocus = FocusNode();
  final _finishFocus = FocusNode();
  final _restFocus = FocusNode();

  LiveSessionState get state => widget.state;

  /// Como en la rutina: si el foco estaba en la barra, pasa a «+15 s» al
  /// empezar el descanso y vuelve a «Apuntar serie» al acabar (WCAG 2.4.3).
  @override
  void didUpdateWidget(_FreeBottomBar old) {
    super.didUpdateWidget(old);
    final wasResting = old.state.restRemaining != null;
    final resting = state.restRemaining != null;
    if (wasResting == resting) return;
    final from = resting ? _doneFocus : _restFocus;
    final to = resting ? _restFocus : _doneFocus;
    if (!from.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && to.canRequestFocus) to.requestFocus();
    });
  }

  @override
  void dispose() {
    _doneFocus.dispose();
    _finishFocus.dispose();
    _restFocus.dispose();
    super.dispose();
  }

  /// Sesión libre: el mismo cronómetro por serie que en una rutina (opcional:
  /// «Apuntar serie N» siempre está a mano) y «Terminar» aparte.
  Widget _freeControls(BuildContext context, VoidCallback? finish) {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    final sets = state.session?.setsFor(null) ?? const <SessionSet>[];
    final next = sets.fold(0, (m, x) => math.max(m, x.setNumber)) + 1;
    final timed = state.timerSet == next && state.timerExerciseId == null;
    final running = timed && state.timerSince != null;
    void resume() => bloc.add(const LiveSessionEvent.resumeRequested());
    // Como en la rutina: el cronómetro es un icono con su nombre en la
    // descripción y «Apuntar serie» es la única acción destacada.
    Widget iconAction(String tooltip, IconData icon, VoidCallback? onTap) =>
        IconButton.outlined(
          tooltip: tooltip,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(TokensSize.controlHeight),
          ),
          onPressed: onTap,
          icon: Icon(icon),
        );
    final Widget timer = state.paused || (timed && !running)
        ? iconAction(l10n.trainingResume, Icons.play_arrow_rounded, resume)
        : !timed
        ? iconAction(
            l10n.trainingSetTimerStart,
            Icons.timer_outlined,
            next > 50
                ? null
                : () => bloc.add(LiveSessionEvent.setTimerStarted(null, next)),
          )
        : iconAction(
            l10n.trainingPause,
            Icons.pause_rounded,
            () => bloc.add(const LiveSessionEvent.pauseRequested()),
          );
    final log = AppPrimaryButton(
      label: timed ? l10n.trainingSetDoneShort : l10n.trainingFreeLogSet(next),
      icon: Icons.check_rounded,
      focusNode: _doneFocus,
      onPressed: state.saving || next > 50
          ? null
          : () => widget.onFreeLog(next),
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
                    // El tiempo ya está en el reloj ⏱ de arriba: aquí no se
                    // repite la cifra.
                    ? (running
                          ? l10n.trainingSetRowInProgress
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
        Row(
          children: [
            timer,
            const SizedBox(width: TokensSpacing.s),
            Expanded(child: log),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Con series sin subir no se puede cerrar: se perderían.
    final finish = state.finishing || state.pendingSets.isNotEmpty
        ? null
        : widget.onFinish;
    // El descanso, con el mismo panel que en la rutina (ADR 0053).
    final resting = state.restRemaining != null;
    return LiveBottomPanel(
      resting: resting,
      // En la libre, «Terminar» solo está aquí: sigue a mano en el descanso.
      child: resting
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LiveRestPanel(
                  state: state,
                  drafts: const {},
                  restFocus: _restFocus,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: finish,
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(context.localizations.trainingFinishAction),
                  ),
                ),
              ],
            )
          : _freeControls(context, finish),
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
  const _ExerciseList({
    required this.state,
    required this.onEdit,
    required this.onUnmark,
  });

  final LiveSessionState state;
  final _EditSet onEdit;
  final void Function(SessionSet set) onUnmark;

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
              // Entrenar con amigos (ADR 0044): solo se ve si lo es.
              const WorkoutTogetherPanel(),
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
                  onUnmark: onUnmark,
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
                    onUnmark: onUnmark,
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
    required this.onUnmark,
  });

  final PlannedExercise exercise;

  /// Mejor serie de la última vez que hizo este ejercicio.
  final PersonalRecord? lastTime;
  final List<SessionSet> sets;
  final bool active;
  final int seconds;
  final bool readOnly;
  final _EditSet onEdit;
  final void Function(SessionSet set) onUnmark;

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
                onUnmark: onUnmark,
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
                    icon: const Icon(AppIcons.howTo),
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
                    icon: const Icon(AppIcons.add),
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
    required this.onUnmark,
  });

  final List<SessionSet> sets;
  final bool readOnly;
  final _EditSet onEdit;
  final void Function(SessionSet set) onUnmark;

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
              onUnmark: onUnmark,
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
                icon: const Icon(AppIcons.add),
                label: Text(l10n.trainingAddSet),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fila de una serie en la vista de lista (sesión libre o terminada): como en
/// la de rutina, el ✓ de una serie hecha la desmarca (con «Deshacer») y el
/// resto de la fila abre la hoja para apuntarla o corregirla.
class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.readOnly,
    required this.onTap,
    required this.onUnmark,
  });

  final int setNumber;
  final SessionSet? set;
  final bool readOnly;
  final VoidCallback onTap;
  final void Function(SessionSet set) onUnmark;

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
    // El lector oye qué hace tocar la fila: corregir la serie ya apuntada.
    return AppFocusOutline(
      borderRadius: BorderRadius.circular(TokensRadius.s),
      child: Semantics(
        onTapHint: s == null || readOnly ? null : l10n.trainingCorrectSession,
        child: InkWell(
          onTap: readOnly ? null : onTap,
          borderRadius: BorderRadius.circular(TokensRadius.s),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TokensLayout.minTouchTarget,
            ),
            child: Row(
              children: [
                if (s != null && !readOnly)
                  IconButton(
                    tooltip: l10n.trainingUnmarkSetNumber(setNumber),
                    onPressed: () => onUnmark(s),
                    icon: Icon(icon, color: color, size: TokensSize.iconM),
                  )
                else
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
                    s == null ? AppIcons.add : AppIcons.edit,
                    size: TokensSize.iconXs,
                    color: context.colors.onSurfaceVariant,
                  ),
              ],
            ),
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

  /// Se puede deshacer, así que no pregunta (vocabulario §4): se hace y el
  /// aviso lleva «Deshacer», que vuelve a las series adaptadas.
  void _decline(BuildContext context) {
    final bloc = context.read<LiveSessionBloc>();
    // La tarjeta (y su botón, que tiene el foco) desaparece: el foco pasa a
    // lo siguiente en vez de volver al principio (WCAG 2.4.3).
    FocusScope.of(context).nextFocus();
    bloc.add(const LiveSessionEvent.adaptationDeclined());
    context.showUndoSnack(
      context.localizations.trainingAdaptedDeclined,
      onUndo: () {
        if (!bloc.isClosed) {
          bloc.add(LiveSessionEvent.adaptationRestored(adaptation));
        }
      },
      onCommit: () {},
    );
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
              Icon(AppIcons.filters, color: onColor),
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
                        SessionAdaptationReason.cycleDiscomfort =>
                          l10n.trainingAdaptedCycle,
                      }, style: style),
                    // Sin porcentaje (vocabulario §4): las líneas de cada
                    // ejercicio ya dicen cuántas series quedan.
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
              // Foco inicial en la acción principal (relleno: su anillo no
              // crea un segundo botón destacado).
              autofocus: true,
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
              l10n.trainingFinishAction,
              planned > 0
                  ? l10n.trainingLeaveFinishHintCount(done, planned)
                  : l10n.trainingLeaveFinishHint,
              primary: false,
            ),
            const SizedBox(height: TokensSpacing.xs),
            // Sin foco inicial: su anillo lo hacía parecer otro botón destacado
            // junto a «Pausar y salir» (§4). Cerrar la hoja también sigue.
            TextButton(
              onPressed: () => Navigator.of(context).pop(_LeaveChoice.stay),
              child: Text(l10n.trainingLeaveStay),
            ),
            // Lo que no guarda, apartado del resto.
            const SizedBox(height: TokensSpacing.m),
            // Descartar no guarda: aparte de «Terminar» y confirmado.
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: context.colors.error,
              ),
              onPressed: () => Navigator.of(context).pop(_LeaveChoice.discard),
              child: Text(l10n.trainingDiscardSession),
            ),
          ],
        ),
      ),
    );
  }
}
