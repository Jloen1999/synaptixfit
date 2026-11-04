import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../../domain/use_cases/training/list_sport_activities_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';

part 'activity_history_bloc.freezed.dart';
part 'activity_history_event.dart';
part 'activity_history_state.dart';

/// «Actividades y partidos» del historial: deporte hecho fuera de las rutinas,
/// paginado. Se refresca al apuntar o marcar deporte en el planificador.
class ActivityHistoryBloc
    extends Bloc<ActivityHistoryEvent, ActivityHistoryState>
    with DataChangeRefreshMixin {
  ActivityHistoryBloc({required this._list, required this._watchDataChanges})
    : super(const ActivityHistoryState()) {
    on<ActivityHistoryStarted>((_, emit) async {
      watchDataChanges(
        _watchDataChanges,
        topics: const {DataTopic.planner},
        onChanged: const ActivityHistoryEvent.started(),
      );
      emit(state.copyWith(loading: true, error: null));
      await _loadPage(emit, 0);
    });
    on<ActivityHistoryMoreRequested>((_, emit) async {
      if (!state.hasMore || state.loadingMore) return;
      emit(state.copyWith(loadingMore: true));
      await _loadPage(emit, state.page + 1);
    });
  }

  static const _size = 20;

  final ListSportActivitiesUseCaseContract _list;
  final WatchDataChangesUseCaseContract _watchDataChanges;

  Future<void> _loadPage(Emitter<ActivityHistoryState> emit, int page) async {
    final result = await _list(page: page, size: _size);
    if (result.errorOrNull case final error?) {
      emit(state.copyWith(loading: false, loadingMore: false, error: error));
      return;
    }
    final data = result.valueOrNull!;
    emit(
      state.copyWith(
        loading: false,
        loadingMore: false,
        error: null,
        items: page == 0 ? data.items : [...state.items, ...data.items],
        page: data.page,
        hasMore: data.hasMore,
      ),
    );
  }
}
