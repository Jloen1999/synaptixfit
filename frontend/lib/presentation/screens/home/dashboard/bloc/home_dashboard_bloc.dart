import '../../../../../domain/models/home/home_setup.dart';
import '../../../../../domain/use_cases/home/get_home_setup_use_case.dart';
import '../../../../../domain/use_cases/home/snooze_home_setup_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/enums/home_event_kind.dart';
import '../../../../../domain/enums/home_event_type.dart';
import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/home/home_dashboard.dart';
import '../../../../../domain/models/home/home_due_review.dart';
import '../../../../../domain/models/planner/weekly_planning.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/home/get_home_dashboard_use_case.dart';
import '../../../../../domain/use_cases/home/get_home_due_reviews_use_case.dart';
import '../../../../../domain/use_cases/home/get_home_onboarding_status_use_case.dart';
import '../../../../../domain/use_cases/profile/is_permissions_intro_pending_use_case.dart';
import '../../../../../domain/use_cases/home/get_home_unread_count_use_case.dart';
import '../../../../../domain/use_cases/planner/delete_block_use_case.dart';
import '../../../../../domain/use_cases/planner/get_timeline_use_case.dart';
import '../../../../../domain/use_cases/planner/reschedule_block_use_case.dart';
import '../../../../../domain/use_cases/planner/set_block_completion_use_case.dart';
import '../../../../../domain/use_cases/planner/set_deadline_completion_use_case.dart';
import '../../../../../domain/use_cases/training/cancel_session_use_case.dart';
import '../../../../../domain/use_cases/training/finish_session_use_case.dart';
import '../../../../../domain/use_cases/training/log_past_session_use_case.dart';
import '../../../../../domain/use_cases/training/start_session_use_case.dart';
import '../../home_onboarding_gate.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';
import '../../../../mixins/deferred_commit_mixin.dart';

part 'home_dashboard_bloc.freezed.dart';
part 'home_dashboard_event.dart';
part 'home_dashboard_state.dart';

/// Pestaña Inicio: resumen del día, agenda de los próximos días (planificador),
/// cuenta atrás de la próxima entrega o examen, repasos, campana y onboarding. Se refresca sola con cualquier cambio de
/// datos; las insignias y el nivel se celebran en el armazón (`AchievementsBloc`).
/// Cierra lo que quedó a medias (ADR 0059): la sesión de entreno (guardar o
/// descartar con «Deshacer») y lo de ayer sin marcar (hecho, a otro día o
/// quitar con «Deshacer», aplazado con [DeferredCommitMixin]).
class HomeDashboardBloc extends Bloc<HomeDashboardEvent, HomeDashboardState>
    with
        DataChangeRefreshMixin<HomeDashboardEvent, HomeDashboardState>,
        DeferredCommitMixin<HomeDashboardState> {
  HomeDashboardBloc({
    required this._getDashboard,
    required this._getDueReviews,
    required this._getUnreadCount,
    required this._getOnboardingStatus,
    required this._getSetup,
    required this._snoozeSetup,
    required this._getTimeline,
    required this._onboardingGate,
    required this._watchChanges,
    required this._startSession,
    required this._setBlockCompletion,
    required this._setDeadlineCompletion,
    required this._permissionsIntroPending,
    required this._finishSession,
    required this._cancelSession,
    required this._logPastSession,
    required this._rescheduleBlock,
    required this._deleteBlock,
    this._clock = DateTime.now,
  }) : super(const HomeDashboardState()) {
    on<HomeDashboardStarted>(_onStarted);
    on<HomeDashboardOnboardingCheckRequested>(
      (event, emit) => _checkOnboarding(event.userId, emit),
    );
    on<HomeDashboardRefreshed>(_onRefreshed);
    on<HomeDashboardOnboardingHandled>(
      (_, emit) => emit(state.copyWith(onboardingRequired: false)),
    );
    on<HomeDashboardPermissionsIntroHandled>(
      (_, emit) => emit(state.copyWith(permissionsIntroRequired: false)),
    );
    on<HomeDashboardTrainingStarted>(_onTrainingStarted);
    on<HomeDashboardSetupSnoozed>(_onSetupSnoozed);
    on<HomeDashboardCompletionSet>(_onCompletionSet);
    on<HomeDashboardUnfinishedSaved>(_onUnfinishedSaved);
    on<HomeDashboardUnfinishedDiscarded>(
      (event, emit) => _defer(
        emit,
        HomeDeferred.session(event.sessionId),
        HomeActionNotice.sessionDiscarded,
      ),
    );
    on<HomeDashboardMissedLogged>(_onMissedLogged);
    on<HomeDashboardMissedMoved>(_onMissedMoved);
    on<HomeDashboardMissedRemoved>(
      (event, emit) => _defer(
        emit,
        HomeDeferred.block(event.eventId),
        HomeActionNotice.removed,
      ),
    );
    on<HomeDashboardDeferredUndone>((event, emit) {
      if (!release(event.key)) return;
      emit(
        state.copyWith(
          deferredKeys: {...state.deferredKeys}..remove(event.key),
        ),
      );
    });
    on<HomeDashboardDeferredCommitted>(_onDeferredCommitted);
    on<HomeDashboardActionNoticeHandled>(
      (_, emit) => emit(state.copyWith(actionNotice: null)),
    );
    on<HomeDashboardUndoExpired>((event, emit) {
      if (state.lastUndoable?.id == event.id) {
        emit(state.copyWith(lastUndoable: null));
      }
    });
    on<HomeDashboardUndoRequested>((_, emit) {
      final last = state.lastUndoable;
      if (last == null) return;
      emit(state.copyWith(lastUndoable: null));
      add(
        HomeDashboardEvent.completionSet(
          id: last.id,
          kind: last.kind,
          completed: !last.completed,
          undo: true,
        ),
      );
    });
    on<HomeDashboardCompletionNoticeHandled>(
      (_, emit) => emit(state.copyWith(completionNotice: null)),
    );
    on<HomeDashboardTrainingHandled>(
      (_, emit) => emit(
        state.copyWith(
          openSessionId: null,
          trainingError: null,
          showUnfinished: false,
        ),
      ),
    );
  }

  /// Número de repasos urgentes que se muestran.
  static const dueReviewsLimit = 5;

  /// Días que abarca la agenda, hoy incluido.
  static const agendaDays = 7;

  final GetHomeDashboardUseCaseContract _getDashboard;
  final GetHomeDueReviewsUseCaseContract _getDueReviews;
  final GetHomeUnreadCountUseCaseContract _getUnreadCount;
  final GetHomeOnboardingStatusUseCaseContract _getOnboardingStatus;
  final GetHomeSetupUseCaseContract _getSetup;
  final SnoozeHomeSetupUseCaseContract _snoozeSetup;
  final GetTimelineUseCaseContract _getTimeline;
  final DateTime Function() _clock;
  final HomeOnboardingGate _onboardingGate;
  final WatchDataChangesUseCaseContract _watchChanges;
  final StartSessionUseCaseContract _startSession;
  final SetBlockCompletionUseCaseContract _setBlockCompletion;
  final SetDeadlineCompletionUseCaseContract _setDeadlineCompletion;
  final IsPermissionsIntroPendingUseCaseContract _permissionsIntroPending;
  final FinishSessionUseCaseContract _finishSession;
  final CancelSessionUseCaseContract _cancelSession;
  final LogPastSessionUseCaseContract _logPastSession;
  final RescheduleBlockUseCaseContract _rescheduleBlock;
  final DeleteBlockUseCaseContract _deleteBlock;

  /// Termina la sesión a medias con lo registrado; el servidor acota la
  /// duración y la apunta en su día. Inicio se refresca con el cambio de datos.
  Future<void> _onUnfinishedSaved(
    HomeDashboardUnfinishedSaved event,
    Emitter<HomeDashboardState> emit,
  ) => _act(
    emit,
    event.sessionId,
    () => _finishSession(
      event.sessionId,
      durationSeconds: event.minutes * 60,
      rpe: event.rpe,
    ),
    (_) => const HomeActionNotice.sessionSaved(),
  );

  Future<void> _onMissedLogged(
    HomeDashboardMissedLogged event,
    Emitter<HomeDashboardState> emit,
  ) => _act(
    emit,
    event.eventId,
    () => _logPastSession(
      routineId: event.routineId,
      dayId: event.dayId,
      date: event.date,
      durationMinutes: event.minutes,
      rpe: event.rpe,
    ),
    (_) => const HomeActionNotice.logged(),
  );

  Future<void> _onMissedMoved(
    HomeDashboardMissedMoved event,
    Emitter<HomeDashboardState> emit,
  ) => _act(
    emit,
    event.eventId,
    () => _rescheduleBlock(event.eventId, start: event.start, end: event.end),
    (change) => HomeActionNotice.moved(change.block.start),
  );

  /// Una acción de las tarjetas de arriba: marca [id] como ocupado, la hace y
  /// avisa del resultado (el resto llega con el refresco de datos).
  Future<void> _act<T>(
    Emitter<HomeDashboardState> emit,
    String id,
    Future<AppResult<T>> Function() call,
    HomeActionNotice Function(T value) done,
  ) async {
    if (state.actingIds.contains(id)) return;
    emit(state.copyWith(actingIds: {...state.actingIds, id}));
    final result = await call();
    emit(
      state.copyWith(
        actingIds: {...state.actingIds}..remove(id),
        actionNotice: result.fold(done, HomeActionNotice.failed),
      ),
    );
  }

  /// Quita [key] de la vista ya y avisa con «Deshacer»; se hace al cerrarse
  /// el aviso (o al cerrarse el bloc, [DeferredCommitMixin]).
  void _defer(
    Emitter<HomeDashboardState> emit,
    String key,
    HomeActionNotice Function(String key) notice,
  ) {
    if (!defer(key)) return;
    emit(
      state.copyWith(
        deferredKeys: {...state.deferredKeys, key},
        actionNotice: notice(key),
      ),
    );
  }

  Future<void> _onDeferredCommitted(
    HomeDashboardDeferredCommitted event,
    Emitter<HomeDashboardState> emit,
  ) async {
    if (!release(event.key)) return;
    final result = await _commit(event.key);
    if (result case Failure(:final error) when error is! NotFoundError) {
      // No se pudo: vuelve a verse y se avisa.
      emit(
        state.copyWith(
          deferredKeys: {...state.deferredKeys}..remove(event.key),
          actionNotice: HomeActionNotice.failed(error),
        ),
      );
    }
    // Hecho (o ya no existía): sigue oculto hasta que el refresco lo quite.
  }

  Future<AppResult<Object?>> _commit(String key) async {
    final sessionId = HomeDeferred.sessionId(key);
    if (sessionId != null) return _cancelSession(sessionId);
    return _deleteBlock(HomeDeferred.blockId(key)!);
  }

  /// Al cerrarse Inicio, lo pendiente se hace ya (su aviso ya no se vería).
  @override
  Future<void> commitDeferred(String id) => _commit(id);

  /// Marca o desmarca con las mismas reglas que el planificador (XP, retos
  /// ligados, racha: todo en el servidor). Lo cambiado se pinta ya con el
  /// estado que devuelve el servidor; el resto llega con el refresco de datos.
  Future<void> _onCompletionSet(
    HomeDashboardCompletionSet event,
    Emitter<HomeDashboardState> emit,
  ) async {
    if (state.completingIds.contains(event.id)) return;
    emit(state.copyWith(completingIds: {...state.completingIds, event.id}));
    final isDeadline = event.kind == HomeEventKind.deadline;
    final result = isDeadline
        ? (await _setDeadlineCompletion(
            event.id,
            completed: event.completed,
          )).map(
            (v) => (v.deadline.completed, v.deadline.timeStatus, v.xpDelta),
          )
        : (await _setBlockCompletion(
            event.id,
            completed: event.completed,
            effort: event.effort,
          )).map((v) => (v.block.completed, v.block.timeStatus, v.xpDelta));
    final busy = {...state.completingIds}..remove(event.id);
    result.fold(
      (value) {
        final (completed, status, xpDelta) = value;
        HomeTodayEvent update(HomeTodayEvent e) => e.id == event.id
            ? e.copyWith(completed: completed, status: status)
            : e;
        final dashboard = state.dashboard;
        final notice = HomeCompletionNoticeDone(
          id: event.id,
          kind: event.kind,
          completed: completed,
          xpDelta: xpDelta,
        );
        emit(
          state.copyWith(
            completingIds: busy,
            dashboard: dashboard?.copyWith(
              todayEvents: dashboard.todayEvents.map(update).toList(),
              // «Lo hice» de lo de ayer: deja de pedirse en cuanto se marca.
              missedEvents: dashboard.missedEvents.map(update).toList(),
            ),
            upcoming: state.upcoming.map(update).toList(),
            completionNotice: notice,
            lastUndoable: event.undo ? null : notice,
          ),
        );
      },
      (error) => emit(
        state.copyWith(
          completingIds: busy,
          completionNotice: HomeCompletionNotice.failed(error),
        ),
      ),
    );
  }

  /// Usuario de la sesión (llega en `started`): el «Ahora no» es suyo.
  String _userId = '';

  /// «Ahora no»: se oculta hasta la fecha que devuelve el caso de uso (si no
  /// se pudo guardar, sigue a la vista).
  Future<void> _onSetupSnoozed(
    HomeDashboardSetupSnoozed event,
    Emitter<HomeDashboardState> emit,
  ) async {
    if (state.setup == null) return;
    final now = _clock();
    final until = (await _snoozeSetup(now, userId: _userId)).valueOrNull;
    final latest = state.setup;
    if (until == null || latest == null) return;
    emit(state.copyWith(setup: latest.copyWith(snoozedUntil: until)));
  }

  Future<void> _onTrainingStarted(
    HomeDashboardTrainingStarted event,
    Emitter<HomeDashboardState> emit,
  ) async {
    if (state.startingTraining) return;
    emit(state.copyWith(startingTraining: true));
    // Una sesión descartada con su «Deshacer» aún abierto se borra ya: si no,
    // el servidor diría que hay una a medias que ya no se ve.
    for (final key in [...state.deferredKeys]) {
      if (HomeDeferred.sessionId(key) != null && release(key)) {
        await _commit(key);
      }
    }
    final result = await _startSession(
      routineId: event.routineId,
      dayId: event.dayId,
    );
    // Con una sesión a medias no hay callejón sin salida: se vuelve a leer
    // Inicio y la página lleva a su tarjeta (ADR 0059).
    if (result case Failure(error: BusinessError(code: _staleSessionCode))) {
      emit(state.copyWith(startingTraining: false, showUnfinished: true));
      await _load(emit);
      return;
    }
    emit(
      result.fold(
        (session) =>
            state.copyWith(startingTraining: false, openSessionId: session.id),
        (error) =>
            state.copyWith(startingTraining: false, trainingError: error),
      ),
    );
  }

  static const _staleSessionCode = 'SESSION_STALE_OPEN';

  Future<void> _onStarted(
    HomeDashboardStarted event,
    Emitter<HomeDashboardState> emit,
  ) async {
    _userId = event.userId;
    // Inicio resume todos los módulos: cualquier cambio le afecta.
    watchDataChanges(
      _watchChanges,
      topics: DataTopic.values.toSet().difference(DataTopic.live),
      onChanged: const HomeDashboardEvent.refreshed(),
    );
    if (state.status != HomeDashboardStatus.loading) {
      emit(state.copyWith(status: HomeDashboardStatus.loading, error: null));
    }
    final loaded = await _load(emit);
    if (!loaded || !event.checkOnboarding) return;
    await _checkOnboarding(event.userId, emit);
  }

  Future<void> _checkOnboarding(
    String userId,
    Emitter<HomeDashboardState> emit,
  ) async {
    if (userId.isEmpty || !_onboardingGate.shouldCheck(userId)) return;
    final status = await _getOnboardingStatus();
    if (status.valueOrNull?.completed == false) {
      emit(state.copyWith(onboardingRequired: true));
    } else if ((await _permissionsIntroPending()).valueOrNull ?? false) {
      // Quien ya hizo el onboarding (o estrena dispositivo) ve una vez el
      // paso «Permisos»; quien lo hace ahora lo ve al terminarlo.
      emit(state.copyWith(permissionsIntroRequired: true));
    }
  }

  Future<void> _onRefreshed(
    HomeDashboardRefreshed event,
    Emitter<HomeDashboardState> emit,
  ) async {
    emit(
      state.dashboard == null
          ? state.copyWith(status: HomeDashboardStatus.loading, error: null)
          : state.copyWith(refreshing: true, error: null),
    );
    await _load(emit);
  }

  /// Una lectura que empezó antes de un «Ahora no» trae el plazo viejo (o
  /// ninguno): se conserva el más reciente para que el aviso no reaparezca.
  HomeSetup? _withLatestSnooze(HomeSetup? loaded) {
    final kept = state.setup?.snoozedUntil;
    final read = loaded?.snoozedUntil;
    if (loaded == null || kept == null) return loaded;
    if (read != null && !read.isBefore(kept)) return loaded;
    return loaded.copyWith(snoozedUntil: kept);
  }

  /// Carga el resumen, los repasos, la agenda y el contador en paralelo. Solo
  /// el resumen es obligatorio: si fallan los demás se muestran vacíos.
  Future<bool> _load(Emitter<HomeDashboardState> emit) async {
    // Hoy sale del resumen del servidor; la agenda trae los días siguientes.
    final now = _clock();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dashboardFuture = _getDashboard();
    final reviewsFuture = _getDueReviews(limit: dueReviewsLimit);
    final unreadFuture = _getUnreadCount();
    final setupFuture = _getSetup(userId: _userId);
    final upcomingFuture = _getTimeline(
      from: tomorrow,
      to: DateTime(now.year, now.month, now.day + agendaDays),
    );
    final dashboard = await dashboardFuture;
    final reviews = await reviewsFuture;
    final unread = await unreadFuture;
    final upcoming = await upcomingFuture;
    final setup = await setupFuture;

    return dashboard.fold(
      (value) {
        emit(
          state.copyWith(
            status: HomeDashboardStatus.loaded,
            dashboard: value,
            error: null,
            refreshing: false,
            dueReviews: reviews.valueOrNull ?? state.dueReviews,
            unreadNotifications:
                unread.valueOrNull ?? state.unreadNotifications,
            upcoming:
                upcoming.valueOrNull?.map(_toEvent).toList() ?? state.upcoming,
            setup: _withLatestSnooze(setup.valueOrNull) ?? state.setup,
          ),
        );
        return true;
      },
      (error) {
        emit(
          state.copyWith(
            status: state.dashboard == null
                ? HomeDashboardStatus.failure
                : HomeDashboardStatus.loaded,
            error: error,
            refreshing: false,
          ),
        );
        return false;
      },
    );
  }

  /// La agenda pinta bloques y entregas igual que los eventos de hoy.
  static HomeTodayEvent _toEvent(TimelineEntry entry) {
    final isDeadline = entry.kind == TimelineKind.deadline;
    return HomeTodayEvent(
      id: entry.id,
      kind: isDeadline ? HomeEventKind.deadline : HomeEventKind.block,
      type: isDeadline
          ? switch (entry.deadlineType) {
              DeadlineType.exam => HomeEventType.exam,
              DeadlineType.assignment => HomeEventType.delivery,
              DeadlineType.presentation => HomeEventType.presentation,
              DeadlineType.other || null => HomeEventType.other,
            }
          : switch (entry.blockType) {
              BlockType.study => HomeEventType.study,
              BlockType.sport => HomeEventType.sport,
              BlockType.classSession => HomeEventType.classSession,
              BlockType.rest => HomeEventType.rest,
              BlockType.meal => HomeEventType.meal,
              BlockType.sleep => HomeEventType.sleep,
              BlockType.exam => HomeEventType.exam,
              BlockType.delivery => HomeEventType.delivery,
              BlockType.review => HomeEventType.review,
              BlockType.personal => HomeEventType.personal,
              null => HomeEventType.other,
            },
      // Sin título, la agenda muestra el tipo («Estudio», «Deporte»...).
      title: entry.title ?? entry.subjectName ?? '',
      start: entry.start,
      end: entry.end,
      completed: entry.completed,
      subjectName: entry.subjectName,
    );
  }
}
