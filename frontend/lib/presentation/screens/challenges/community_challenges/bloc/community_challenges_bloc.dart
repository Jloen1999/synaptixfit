import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/enums/challenge_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/challenges/clone_challenge_use_case.dart';
import '../../../../../domain/use_cases/challenges/list_community_challenges_use_case.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';

part 'community_challenges_bloc.freezed.dart';
part 'community_challenges_event.dart';
part 'community_challenges_state.dart';

/// Retos activos de otros usuarios, con filtro por tipo, búsqueda y clonado.
/// Se refresca solo cuando cambian retos o gamificación.
class CommunityChallengesBloc
    extends Bloc<CommunityChallengesEvent, CommunityChallengesState>
    with
        DataChangeRefreshMixin<
          CommunityChallengesEvent,
          CommunityChallengesState
        > {
  CommunityChallengesBloc({
    required this._listCommunity,
    required CloneChallengeUseCaseContract cloneChallenge,
    required this._watchChanges,
  }) : _clone = cloneChallenge,
       super(const CommunityChallengesState()) {
    on<CommunityChallengesStarted>(_onStarted);
    on<CommunityChallengesRefreshed>((_, emit) => _load(emit));
    on<CommunityChallengesFiltersChanged>(_onFiltersChanged);
    on<CommunityChallengesLoadMoreRequested>(_onLoadMore);
    on<CommunityChallengesCloneRequested>(_onClone);
  }

  static const pageSize = 20;

  final ListCommunityChallengesUseCaseContract _listCommunity;
  final CloneChallengeUseCaseContract _clone;
  final WatchDataChangesUseCaseContract _watchChanges;
  int _version = 0;

  Future<void> _onStarted(
    CommunityChallengesStarted event,
    Emitter<CommunityChallengesState> emit,
  ) async {
    watchDataChanges(
      _watchChanges,
      topics: const {DataTopic.challenges, DataTopic.gamification},
      onChanged: const CommunityChallengesEvent.refreshed(),
    );
    emit(state.copyWith(status: CommunityChallengesStatus.loading));
    await _load(emit);
  }

  Future<void> _onFiltersChanged(
    CommunityChallengesFiltersChanged event,
    Emitter<CommunityChallengesState> emit,
  ) async {
    if (event.type == state.type && event.search == state.search) return;
    emit(
      state.copyWith(type: event.type, search: event.search, listLoading: true),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<CommunityChallengesState> emit) async {
    final version = ++_version;
    final result = await _listCommunity(
      type: state.type,
      search: state.search,
      size: pageSize,
    );
    if (version != _version) return;
    emit(
      result.fold(
        (page) => state.copyWith(
          status: CommunityChallengesStatus.ready,
          challenges: page.items,
          page: page.page,
          hasMore: page.hasMore,
          listLoading: false,
          error: null,
        ),
        (error) => state.copyWith(
          status: CommunityChallengesStatus.failure,
          listLoading: false,
          error: error,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    CommunityChallengesLoadMoreRequested event,
    Emitter<CommunityChallengesState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore || state.listLoading) return;
    final version = _version;
    emit(state.copyWith(loadingMore: true));
    final result = await _listCommunity(
      type: state.type,
      search: state.search,
      page: state.page + 1,
      size: pageSize,
    );
    if (version != _version) return;
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            challenges: [...state.challenges, ...value.items],
            page: value.page,
            hasMore: value.hasMore,
            loadingMore: false,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(loadingMore: false));
        _emitEffect(emit, CommunityChallengesEffect.failure(error));
    }
  }

  Future<void> _onClone(
    CommunityChallengesCloneRequested event,
    Emitter<CommunityChallengesState> emit,
  ) async {
    if (state.cloningId != null) return;
    emit(state.copyWith(cloningId: event.challengeId));
    final result = await _clone(event.challengeId);
    emit(state.copyWith(cloningId: null));
    _emitEffect(
      emit,
      result.fold(
        CommunityChallengesEffect.cloned,
        CommunityChallengesEffect.failure,
      ),
    );
  }

  void _emitEffect(
    Emitter<CommunityChallengesState> emit,
    CommunityChallengesEffect effect,
  ) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
