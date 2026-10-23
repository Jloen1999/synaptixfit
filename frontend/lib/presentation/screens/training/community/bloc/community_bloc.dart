import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/use_cases/training/clone_routine_use_case.dart';
import '../../../../../domain/use_cases/training/get_community_routines_use_case.dart';
import '../../training_effect.dart';

part 'community_bloc.freezed.dart';
part 'community_event.dart';
part 'community_state.dart';

/// Rutinas públicas y de amigos con búsqueda, filtro por objetivo y clonado.
class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  CommunityBloc({required this._getCommunity, required this._clone})
    : super(const CommunityState()) {
    on<CommunityStarted>((e, emit) => _loadFirst(emit));
    on<CommunityQueryChanged>(
      (e, emit) => _loadFirst(emit, query: e.query, goal: state.goal),
    );
    on<CommunityGoalChanged>(
      (e, emit) => _loadFirst(emit, query: state.query, goal: e.goal),
    );
    on<CommunityRefreshed>(
      (e, emit) =>
          _loadFirst(emit, query: state.query, goal: state.goal, silent: true),
    );
    on<CommunityMoreRequested>(_onMore);
    on<CommunityCloneRequested>(_onClone);
  }

  final GetCommunityRoutinesUseCaseContract _getCommunity;
  final CloneRoutineUseCaseContract _clone;

  Future<void> _loadFirst(
    Emitter<CommunityState> emit, {
    String query = '',
    TrainingGoal? goal,
    bool silent = false,
  }) async {
    emit(
      state.copyWith(
        query: query,
        goal: goal,
        status: silent ? state.status : CommunityStatus.loading,
        refreshing: silent,
      ),
    );
    final result = await _getCommunity(query: query, goal: goal);
    if (state.query != query || state.goal != goal) return;
    emit(
      result.fold(
        (page) => state.copyWith(
          status: CommunityStatus.ready,
          refreshing: false,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          error: null,
        ),
        (error) => state.copyWith(
          status: CommunityStatus.failure,
          refreshing: false,
          error: error,
        ),
      ),
    );
  }

  Future<void> _onMore(
    CommunityMoreRequested event,
    Emitter<CommunityState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore) return;
    final query = state.query;
    final goal = state.goal;
    emit(state.copyWith(loadingMore: true));
    final result = await _getCommunity(
      query: query,
      goal: goal,
      page: state.page + 1,
    );
    if (state.query != query || state.goal != goal) return;
    emit(
      result.fold(
        (page) => state.copyWith(
          loadingMore: false,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ),
        (_) => state.copyWith(loadingMore: false),
      ),
    );
  }

  Future<void> _onClone(
    CommunityCloneRequested event,
    Emitter<CommunityState> emit,
  ) async {
    if (state.cloningId != null) return;
    emit(state.copyWith(cloningId: event.routineId));
    final result = await _clone(event.routineId);
    emit(state.copyWith(cloningId: null));
    switch (result) {
      case Success(value: final copy):
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.routineCloned),
        );
        _effect(emit, TrainingEffect.openRoutine(copy.id));
      case Failure(:final error):
        _effect(emit, TrainingEffect.error(error));
    }
  }

  void _effect(Emitter<CommunityState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
