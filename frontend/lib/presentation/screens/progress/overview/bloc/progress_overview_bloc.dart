import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/home/home_dashboard.dart';
import '../../../../../domain/models/progress/progress_overview.dart';
import '../../../../../domain/models/progress/streak.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/use_cases/academic/get_due_study_materials_use_case.dart';
import '../../../../../domain/use_cases/home/get_home_dashboard_use_case.dart';
import '../../../../../domain/use_cases/progress/get_progress_overview_use_case.dart';
import '../../../../../domain/use_cases/progress/pause_streak_use_case.dart';
import '../../../../../domain/use_cases/progress/resume_streak_use_case.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';

part 'progress_overview_bloc.freezed.dart';
part 'progress_overview_event.dart';
part 'progress_overview_state.dart';

/// Pestaña Progreso: nivel, racha, insignias, resumen semanal, carga física y
/// comunidad. Se refresca sola con gamificación, entrenamiento, social y perfil.
class ProgressOverviewBloc
    extends Bloc<ProgressOverviewEvent, ProgressOverviewState>
    with DataChangeRefreshMixin<ProgressOverviewEvent, ProgressOverviewState> {
  ProgressOverviewBloc({
    required this._getOverview,
    required this._getToday,
    required this._getDueMaterials,
    required this._watchChanges,
    required this._pauseStreak,
    required this._resumeStreak,
  }) : super(const ProgressOverviewState.loading()) {
    on<ProgressOverviewStarted>(_onStarted);
    on<ProgressOverviewRefreshed>(_onRefreshed);
    on<ProgressOverviewBalanceRequested>(_onBalanceRequested);
    on<ProgressOverviewReviewRequested>(_onReviewRequested);
    on<ProgressOverviewReviewHandled>(_onReviewHandled);
    on<ProgressOverviewStreakPaused>(_onStreakPaused);
    on<ProgressOverviewStreakResumed>(_onStreakResumed);
    on<ProgressOverviewStreakHandled>(_onStreakHandled);
  }

  final GetProgressOverviewUseCaseContract _getOverview;

  /// Resumen de hoy (carga cognitiva, carga física y energía), el mismo que
  /// el de Inicio: «Tu equilibrio» se ve aquí (ADR 0038). Es opcional: si
  /// falla, el resto de Progreso se ve y la tarjeta dice el error con
  /// «Reintentar» (`todayError`, ADR 0039). Es la lectura más cara de la
  /// pestaña (unas 60 consultas, el 60 % de las de entrar) y la tarjeta va
  /// plegada en «Ver más cifras»: solo se pide al desplegarla (ADR 0066).
  final GetHomeDashboardUseCaseContract _getToday;

  /// Se desplegó «Ver más cifras»: desde entonces las recargas también leen
  /// «Tu equilibrio».
  bool _balanceWanted = false;

  /// Cola de repaso: el resumen solo trae cuántos hay, así que los ids se
  /// piden al tocar «Ver N repasos pendientes» (y no en cada carga).
  final GetDueStudyMaterialsUseCaseContract _getDueMaterials;
  final WatchDataChangesUseCaseContract _watchChanges;
  final PauseStreakUseCaseContract _pauseStreak;
  final ResumeStreakUseCaseContract _resumeStreak;

  /// La racha que devuelve el servidor se pinta ya; la recarga que dispara el
  /// cambio (`DataTopic.gamification`) pone al día el resto.
  Future<void> _onStreakPaused(
    ProgressOverviewStreakPaused event,
    Emitter<ProgressOverviewState> emit,
  ) => _updateStreak(emit, _pauseStreak.call, paused: true);

  Future<void> _onStreakResumed(
    ProgressOverviewStreakResumed event,
    Emitter<ProgressOverviewState> emit,
  ) => _updateStreak(emit, _resumeStreak.call, paused: false);

  Future<void> _updateStreak(
    Emitter<ProgressOverviewState> emit,
    Future<AppResult<Streak>> Function() action, {
    required bool paused,
  }) async {
    final current = state;
    if (current is! ProgressOverviewLoaded || current.updatingStreak) return;
    emit(
      current.copyWith(
        updatingStreak: true,
        streakError: null,
        streakJustPaused: null,
      ),
    );
    final result = await action();
    final latest = state;
    if (latest is! ProgressOverviewLoaded) return;
    emit(
      result.fold(
        (streak) => latest.copyWith(
          overview: latest.overview.copyWith(streak: streak),
          updatingStreak: false,
          streakJustPaused: paused ? streak : null,
        ),
        (error) => latest.copyWith(updatingStreak: false, streakError: error),
      ),
    );
  }

  void _onStreakHandled(
    ProgressOverviewStreakHandled event,
    Emitter<ProgressOverviewState> emit,
  ) {
    final current = state;
    if (current is! ProgressOverviewLoaded) return;
    emit(current.copyWith(streakJustPaused: null, streakError: null));
  }

  Future<void> _onBalanceRequested(
    ProgressOverviewBalanceRequested event,
    Emitter<ProgressOverviewState> emit,
  ) async {
    _balanceWanted = true;
    final current = state;
    if (current is! ProgressOverviewLoaded ||
        current.loadingToday ||
        current.today != null) {
      return;
    }
    emit(current.copyWith(loadingToday: true, todayError: null));
    final result = await _getToday();
    final latest = state;
    if (latest is! ProgressOverviewLoaded) return;
    emit(
      latest.copyWith(
        loadingToday: false,
        today: result.valueOrNull ?? latest.today,
        todayError: result.errorOrNull,
      ),
    );
  }

  Future<void> _onReviewRequested(
    ProgressOverviewReviewRequested event,
    Emitter<ProgressOverviewState> emit,
  ) async {
    final current = state;
    if (current is! ProgressOverviewLoaded || current.openingReview) return;
    emit(current.copyWith(openingReview: true, reviewError: null));
    final result = await _getDueMaterials();
    final latest = state;
    if (latest is! ProgressOverviewLoaded) return;
    emit(
      result.fold(
        (materials) => latest.copyWith(
          openingReview: false,
          reviewQueue: [for (final m in materials) m.id],
        ),
        (error) => latest.copyWith(openingReview: false, reviewError: error),
      ),
    );
  }

  void _onReviewHandled(
    ProgressOverviewReviewHandled event,
    Emitter<ProgressOverviewState> emit,
  ) {
    final current = state;
    if (current is! ProgressOverviewLoaded) return;
    emit(current.copyWith(reviewQueue: null, reviewError: null));
  }

  Future<void> _onStarted(
    ProgressOverviewStarted event,
    Emitter<ProgressOverviewState> emit,
  ) async {
    watchDataChanges(
      _watchChanges,
      topics: const {
        DataTopic.gamification,
        DataTopic.training,
        DataTopic.social,
        DataTopic.profile,
        // «Tu estudio»: concentración y bloques (planner), repasos y simulacros.
        DataTopic.planner,
        DataTopic.academic,
      },
      onChanged: const ProgressOverviewEvent.refreshed(),
    );
    emit(const ProgressOverviewState.loading());
    await _load(emit);
  }

  Future<void> _onRefreshed(
    ProgressOverviewRefreshed event,
    Emitter<ProgressOverviewState> emit,
  ) async {
    final current = state;
    if (current is! ProgressOverviewLoaded) {
      emit(const ProgressOverviewState.loading());
      return _load(emit);
    }
    emit(current.copyWith(refreshing: true, refreshError: null));
    final todayF = _balanceWanted ? _getToday() : null;
    final result = await _getOverview();
    final todayResult = await todayF;
    final today = todayResult?.valueOrNull ?? current.today;
    emit(
      result.fold(
        (overview) => ProgressOverviewState.loaded(
          overview,
          today: today,
          todayError: today == null ? todayResult?.errorOrNull : null,
        ),
        (error) => current.copyWith(refreshing: false, refreshError: error),
      ),
    );
  }

  Future<void> _load(Emitter<ProgressOverviewState> emit) async {
    final todayF = _balanceWanted ? _getToday() : null;
    final result = await _getOverview();
    final todayResult = await todayF;
    emit(
      result.fold(
        (overview) => ProgressOverviewState.loaded(
          overview,
          today: todayResult?.valueOrNull,
          todayError: todayResult?.errorOrNull,
        ),
        ProgressOverviewState.failure,
      ),
    );
  }
}
