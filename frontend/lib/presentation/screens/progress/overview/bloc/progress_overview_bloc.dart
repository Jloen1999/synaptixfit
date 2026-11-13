import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/home/home_dashboard.dart';
import '../../../../../domain/models/progress/progress_overview.dart';
import '../../../../../domain/use_cases/home/get_home_dashboard_use_case.dart';
import '../../../../../domain/use_cases/progress/get_progress_overview_use_case.dart';
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
    required this._watchChanges,
  }) : super(const ProgressOverviewState.loading()) {
    on<ProgressOverviewStarted>(_onStarted);
    on<ProgressOverviewRefreshed>(_onRefreshed);
  }

  final GetProgressOverviewUseCaseContract _getOverview;

  /// Resumen de hoy (carga cognitiva, carga física y energía), el mismo que
  /// el de Inicio: «Tu equilibrio» se ve aquí (ADR 0038). Es opcional: si
  /// falla, el resto de Progreso se ve y la tarjeta dice el error con
  /// «Reintentar» (`todayError`, ADR 0039).
  final GetHomeDashboardUseCaseContract _getToday;
  final WatchDataChangesUseCaseContract _watchChanges;

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
    final todayF = _getToday();
    final result = await _getOverview();
    final todayResult = await todayF;
    final today = todayResult.valueOrNull ?? current.today;
    emit(
      result.fold(
        (overview) => ProgressOverviewState.loaded(
          overview,
          today: today,
          todayError: today == null ? todayResult.errorOrNull : null,
        ),
        (error) => current.copyWith(refreshing: false, refreshError: error),
      ),
    );
  }

  Future<void> _load(Emitter<ProgressOverviewState> emit) async {
    final todayF = _getToday();
    final result = await _getOverview();
    final todayResult = await todayF;
    emit(
      result.fold(
        (overview) => ProgressOverviewState.loaded(
          overview,
          today: todayResult.valueOrNull,
          todayError: todayResult.errorOrNull,
        ),
        ProgressOverviewState.failure,
      ),
    );
  }
}
