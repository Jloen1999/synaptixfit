import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/recommendation.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/training_week.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../../domain/models/training/wellbeing.dart';
import '../../../../../domain/use_cases/training/apply_recommendation_use_case.dart';
import '../../../../../domain/use_cases/training/cancel_session_use_case.dart';
import '../../../../../domain/use_cases/training/discard_recommendation_use_case.dart';
import '../../../../../domain/use_cases/training/finish_session_use_case.dart';
import '../../../../../domain/use_cases/training/get_my_routines_use_case.dart';
import '../../../../../domain/use_cases/training/get_open_sessions_use_case.dart';
import '../../../../../domain/use_cases/training/get_pending_day_use_case.dart';
import '../../../../../domain/use_cases/training/get_training_week_use_case.dart';
import '../../../../../domain/use_cases/training/get_recommendations_use_case.dart';
import '../../../../../domain/use_cases/training/get_today_check_in_use_case.dart';
import '../../../../../domain/use_cases/training/restart_routine_use_case.dart';
import '../../../../../domain/use_cases/training/skip_routine_day_use_case.dart';
import '../../../../../domain/use_cases/training/unskip_routine_day_use_case.dart';
import '../../../../../domain/use_cases/training/start_session_use_case.dart';
import '../../training_effect.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';
import '../../../../mixins/deferred_commit_mixin.dart';

part 'training_home_bloc.freezed.dart';
part 'training_home_event.dart';
part 'training_home_state.dart';

/// Pestaña Rutinas: día que toca (con su fecha y si va con retraso), sesiones
/// abandonadas por cerrar, mis rutinas, check-in de hoy y sugerencias. Se
/// refresca sola cuando cambian entrenamiento, perfil o planificador.
///
/// Qué día toca, cuándo y si una sesión está abandonada lo decide el servidor:
/// aquí solo se muestra y se piden las acciones.
class TrainingHomeBloc extends Bloc<TrainingHomeEvent, TrainingHomeState>
    with
        DataChangeRefreshMixin<TrainingHomeEvent, TrainingHomeState>,
        DeferredCommitMixin<TrainingHomeState> {
  TrainingHomeBloc({
    required this._getPendingDay,
    required this._getWeek,
    required this._getMyRoutines,
    required this._getTodayCheckIn,
    required this._getRecommendations,
    required this._applyRecommendation,
    required this._discardRecommendation,
    required this._startSession,
    required this._watchChanges,
    required this._getOpenSessions,
    required this._skipDay,
    required this._unskipDay,
    required this._finishSession,
    required this._discardSession,
    required this._restartRoutine,
  }) : super(const TrainingHomeState()) {
    on<TrainingHomeStarted>(_onLoad);
    on<TrainingHomeRefreshed>(_onLoad);
    on<TrainingHomeRecommendationApplied>(_onApply);
    on<TrainingHomeRecommendationDiscarded>(_onDiscard);
    on<TrainingHomeRecommendationRestored>((e, emit) {
      release(e.recommendation.id);
      emit(
        state.copyWith(
          recommendations: [e.recommendation, ...state.recommendations],
        ),
      );
    });
    on<TrainingHomeRecommendationDiscardConfirmed>(_onDiscardConfirmed);
    on<TrainingHomeSessionStarted>(_onStartSession);
    on<TrainingHomeDaySkipped>(
      (e, emit) => _act(
        emit,
        () => _skipDay(e.routineId, e.dayId),
        TrainingMessage.daySkipped,
        effect: TrainingEffect.daySkipped(
          routineId: e.routineId,
          dayId: e.dayId,
        ),
      ),
    );
    // «Deshacer» del aviso: saltar es reversible y no se confirma (vocabulario §4).
    on<TrainingHomeDayUnskipped>(
      (e, emit) => _act(
        emit,
        () => _unskipDay(e.routineId, e.dayId),
        TrainingMessage.dayUnskipped,
      ),
    );
    on<TrainingHomeStaleFinished>(
      (e, emit) => _act(
        emit,
        () => _finishSession(
          e.sessionId,
          durationSeconds: e.minutes * 60,
          rpe: e.rpe,
        ),
        TrainingMessage.sessionSavedOnItsDay,
      ),
    );
    on<TrainingHomeStaleDiscarded>(
      (e, emit) => _act(
        emit,
        () => _discardSession(e.sessionId),
        TrainingMessage.sessionDiscarded,
      ),
    );
    on<TrainingHomeCycleRestarted>(
      (e, emit) => _act(
        emit,
        () => _restartRoutine(e.routineId),
        TrainingMessage.routineRestarted,
      ),
    );
  }

  final GetPendingDayUseCaseContract _getPendingDay;
  final GetTrainingWeekUseCaseContract _getWeek;
  final GetMyRoutinesUseCaseContract _getMyRoutines;
  final GetTodayCheckInUseCaseContract _getTodayCheckIn;
  final GetRecommendationsUseCaseContract _getRecommendations;
  final ApplyRecommendationUseCaseContract _applyRecommendation;
  final DiscardRecommendationUseCaseContract _discardRecommendation;
  final StartSessionUseCaseContract _startSession;
  final WatchDataChangesUseCaseContract _watchChanges;
  final GetOpenSessionsUseCaseContract _getOpenSessions;
  final SkipRoutineDayUseCaseContract _skipDay;
  final UnskipRoutineDayUseCaseContract _unskipDay;
  final FinishSessionUseCaseContract _finishSession;
  final CancelSessionUseCaseContract _discardSession;
  final RestartRoutineUseCaseContract _restartRoutine;

  static const _routinesPageSize = 50;

  Future<void> _onLoad(
    TrainingHomeEvent event,
    Emitter<TrainingHomeState> emit,
  ) async {
    if (event is TrainingHomeStarted) {
      watchDataChanges(
        _watchChanges,
        topics: const {
          DataTopic.training,
          DataTopic.profile,
          DataTopic.planner,
        },
        onChanged: const TrainingHomeEvent.refreshed(),
      );
    }
    if (event is TrainingHomeStarted || state.status == HomeStatus.failure) {
      emit(state.copyWith(status: HomeStatus.loading, error: null));
    } else {
      emit(state.copyWith(refreshing: true));
    }
    final pendingFuture = _getPendingDay();
    final weekFuture = _getWeek();
    final routinesFuture = _getMyRoutines(size: _routinesPageSize);
    final checkInFuture = _getTodayCheckIn();
    final recommendationsFuture = _getRecommendations(applied: false);
    final openFuture = _getOpenSessions();

    final pending = await pendingFuture;
    final routines = await routinesFuture;
    final checkIn = await checkInFuture;
    final recommendations = await recommendationsFuture;
    final open = await openFuture;
    final week = await weekFuture;

    final error = pending.errorOrNull ?? routines.errorOrNull;
    if (error != null) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          error: error,
          refreshing: false,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: HomeStatus.ready,
        error: null,
        refreshing: false,
        pendingDay: pending.valueOrNull,
        // Un extra: si falla, se conserva la última semana leída.
        week: week.valueOrNull ?? state.week,
        routines: routines.valueOrNull?.items ?? const [],
        todayCheckIn: checkIn.valueOrNull,
        recommendations: [
          for (final r in recommendations.valueOrNull?.items ?? const [])
            if (!isDeferred(r.id)) r,
        ],
        // Un extra: si falla, la pestaña se muestra igual.
        staleSessions: [
          for (final s in open.valueOrNull ?? const <OpenSession>[])
            if (s.stale) s,
        ],
      ),
    );
  }

  /// Acción que cambia el avance: avisa y recarga (el servidor recalcula qué
  /// toca después).
  Future<void> _act(
    Emitter<TrainingHomeState> emit,
    Future<AppResult<Object?>> Function() call,
    TrainingMessage message, {
    TrainingEffect? effect,
  }) async {
    if (state.working) return;
    emit(state.copyWith(working: true));
    final result = await call();
    emit(state.copyWith(working: false));
    switch (result) {
      case Success():
        _effect(emit, effect ?? TrainingEffect.message(message));
        add(const TrainingHomeEvent.refreshed());
      case Failure(:final error):
        _effect(emit, TrainingEffect.error(error));
    }
  }

  Future<void> _onApply(
    TrainingHomeRecommendationApplied event,
    Emitter<TrainingHomeState> emit,
  ) async {
    final applied = state.recommendations
        .where((r) => r.id == event.recommendationId)
        .firstOrNull;
    emit(state.copyWith(busyIds: {...state.busyIds, event.recommendationId}));
    final result = await _applyRecommendation(event.recommendationId);
    final busy = {...state.busyIds}..remove(event.recommendationId);
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            busyIds: busy,
            recommendations: state.recommendations
                .where((r) => r.id != event.recommendationId)
                .toList(),
          ),
        );
        _effect(
          emit,
          TrainingEffect.recommendationApplied(routineId: applied?.routineId),
        );
        // Los parámetros de la rutina han cambiado: se recarga el día pendiente.
        add(const TrainingHomeEvent.refreshed());
      case Failure(:final error):
        emit(state.copyWith(busyIds: busy));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  void _onDiscard(
    TrainingHomeRecommendationDiscarded event,
    Emitter<TrainingHomeState> emit,
  ) {
    final id = event.recommendationId;
    final recommendation = state.recommendations
        .where((r) => r.id == id)
        .firstOrNull;
    if (recommendation == null) return;
    defer(id);
    emit(
      state.copyWith(
        recommendations: state.recommendations
            .where((r) => r.id != id)
            .toList(),
      ),
    );
    _effect(emit, TrainingEffect.recommendationDiscarded(recommendation));
  }

  Future<void> _onDiscardConfirmed(
    TrainingHomeRecommendationDiscardConfirmed event,
    Emitter<TrainingHomeState> emit,
  ) async {
    if (!release(event.recommendationId)) return;
    final result = await _discardRecommendation(event.recommendationId);
    if (result case Failure(:final error)) {
      _effect(emit, TrainingEffect.error(error));
      add(const TrainingHomeEvent.refreshed());
    }
  }

  /// Sugerencia quitada con su aviso de «Deshacer» abierto: no vuelve con una
  /// recarga y se descarta al cerrarse el aviso o, si antes se cierra el bloc,
  /// al cerrarse.
  @override
  Future<void> commitDeferred(String id) => _discardRecommendation(id);

  Future<void> _onStartSession(
    TrainingHomeSessionStarted event,
    Emitter<TrainingHomeState> emit,
  ) async {
    if (state.startingSession) return;
    emit(state.copyWith(startingSession: true));
    final result = await _startSession(
      routineId: event.routineId,
      dayId: event.dayId,
    );
    emit(state.copyWith(startingSession: false));
    _effect(
      emit,
      result.fold(
        (session) => TrainingEffect.openSession(session.id),
        TrainingEffect.error,
      ),
    );
  }

  void _effect(Emitter<TrainingHomeState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
