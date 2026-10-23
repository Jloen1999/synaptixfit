import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/use_cases/training/get_exercise_filters_use_case.dart';
import '../../../../../domain/use_cases/training/search_exercises_use_case.dart';

part 'exercise_explorer_bloc.freezed.dart';
part 'exercise_explorer_event.dart';
part 'exercise_explorer_state.dart';

/// Explorador del catálogo con filtros y paginación (también selector de ejercicios).
class ExerciseExplorerBloc
    extends Bloc<ExerciseExplorerEvent, ExerciseExplorerState> {
  ExerciseExplorerBloc({required this._search, required this._getFilters})
    : super(const ExerciseExplorerState()) {
    on<ExerciseExplorerStarted>(_onStarted);
    on<ExerciseExplorerCriteriaChanged>(
      (e, emit) => _searchFirstPage(emit, e.criteria),
    );
    on<ExerciseExplorerRefreshed>(
      (e, emit) => _searchFirstPage(emit, state.criteria, silent: true),
    );
    on<ExerciseExplorerMoreRequested>(_onMore);
  }

  final SearchExercisesUseCaseContract _search;
  final GetExerciseFiltersUseCaseContract _getFilters;

  static const pageSize = 24;

  Future<void> _onStarted(
    ExerciseExplorerStarted event,
    Emitter<ExerciseExplorerState> emit,
  ) async {
    final filtersFuture = _getFilters();
    await _searchFirstPage(emit, state.criteria);
    final filters = await filtersFuture;
    emit(state.copyWith(filters: filters.valueOrNull));
  }

  Future<void> _searchFirstPage(
    Emitter<ExerciseExplorerState> emit,
    ExerciseSearchCriteria criteria, {
    bool silent = false,
  }) async {
    emit(
      state.copyWith(
        criteria: criteria,
        status: silent ? state.status : ExplorerStatus.loading,
        error: null,
      ),
    );
    final result = await _search(criteria, size: pageSize);
    // Si los criterios cambiaron mientras tanto, se ignora la respuesta antigua.
    if (state.criteria != criteria) return;
    switch (result) {
      case Success(value: final page):
        emit(
          state.copyWith(
            status: ExplorerStatus.ready,
            items: page.items,
            page: page.page,
            hasMore: page.hasMore,
            totalItems: page.totalItems,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(status: ExplorerStatus.failure, error: error));
    }
  }

  Future<void> _onMore(
    ExerciseExplorerMoreRequested event,
    Emitter<ExerciseExplorerState> emit,
  ) async {
    if (!state.hasMore ||
        state.loadingMore ||
        state.status != ExplorerStatus.ready) {
      return;
    }
    final criteria = state.criteria;
    emit(state.copyWith(loadingMore: true));
    final result = await _search(
      criteria,
      page: state.page + 1,
      size: pageSize,
    );
    if (state.criteria != criteria) return;
    switch (result) {
      case Success(value: final page):
        emit(
          state.copyWith(
            loadingMore: false,
            items: [...state.items, ...page.items],
            page: page.page,
            hasMore: page.hasMore,
          ),
        );
      case Failure():
        emit(state.copyWith(loadingMore: false));
    }
  }
}
