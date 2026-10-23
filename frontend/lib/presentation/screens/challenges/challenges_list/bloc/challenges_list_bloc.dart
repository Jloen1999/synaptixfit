import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/challenges/challenge_page.dart';
import '../../../../../domain/models/challenges/challenge_query.dart';
import '../../../../../domain/models/challenges/challenge_summary.dart';
import '../../../../../domain/models/challenges/pending_milestone.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/challenges/get_challenge_summary_use_case.dart';
import '../../../../../domain/use_cases/challenges/list_my_challenges_use_case.dart';
import '../../../../../domain/use_cases/challenges/list_pending_milestones_use_case.dart';
import '../../../../../domain/use_cases/challenges/set_milestone_completion_use_case.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';

part 'challenges_list_bloc.freezed.dart';
part 'challenges_list_event.dart';
part 'challenges_list_state.dart';

/// Pestaña «Mis retos»: resumen, tareas pendientes y listado filtrado y paginado.
/// Se refresca sola cuando cambian retos o gamificación.
class ChallengesListBloc extends Bloc<ChallengesListEvent, ChallengesListState>
    with DataChangeRefreshMixin<ChallengesListEvent, ChallengesListState> {
  ChallengesListBloc({
    required this._listMine,
    required this._summary,
    required this._pending,
    required this._setMilestoneCompletion,
    required this._getAccount,
    required this._watchChanges,
  }) : super(const ChallengesListState()) {
    on<ChallengesListStarted>(_onStarted);
    on<ChallengesListRefreshed>(_onRefreshed);
    on<ChallengesListQueryChanged>(_onQueryChanged);
    on<ChallengesListLoadMoreRequested>(_onLoadMore);
    on<ChallengesListPendingCompleted>(_onPendingCompleted);
  }

  static const pageSize = 20;

  final ListMyChallengesUseCaseContract _listMine;
  final GetChallengeSummaryUseCaseContract _summary;
  final ListPendingMilestonesUseCaseContract _pending;
  final SetMilestoneCompletionUseCaseContract _setMilestoneCompletion;
  final GetAccountUseCaseContract _getAccount;
  final WatchDataChangesUseCaseContract _watchChanges;

  /// Descarta respuestas de consultas que ya no son la última.
  int _queryVersion = 0;

  Future<void> _onStarted(
    ChallengesListStarted event,
    Emitter<ChallengesListState> emit,
  ) async {
    watchDataChanges(
      _watchChanges,
      topics: const {DataTopic.challenges, DataTopic.gamification},
      onChanged: const ChallengesListEvent.refreshed(),
    );
    emit(state.copyWith(status: ChallengesListStatus.loading, error: null));
    await _loadAll(emit);
  }

  Future<void> _onRefreshed(
    ChallengesListRefreshed event,
    Emitter<ChallengesListState> emit,
  ) => _loadAll(emit);

  Future<void> _loadAll(Emitter<ChallengesListState> emit) async {
    final version = ++_queryVersion;
    final results = await Future.wait([
      _listMine(query: state.query, size: pageSize),
      _summary(),
      _pending(),
    ]);
    if (version != _queryVersion) return;
    final page = results[0] as Result<ChallengePage, AppError>;
    final summary = results[1] as Result<ChallengeSummary, AppError>;
    final pending = results[2] as Result<List<PendingMilestone>, AppError>;
    switch (page) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: ChallengesListStatus.ready,
            challenges: value.items,
            page: value.page,
            hasMore: value.hasMore,
            listLoading: false,
            summary: summary.valueOrNull ?? state.summary,
            pending: pending.valueOrNull ?? state.pending,
            error: null,
          ),
        );
      case Failure(:final error):
        emit(
          state.copyWith(
            status: ChallengesListStatus.failure,
            listLoading: false,
            error: error,
          ),
        );
    }
  }

  Future<void> _onQueryChanged(
    ChallengesListQueryChanged event,
    Emitter<ChallengesListState> emit,
  ) async {
    if (event.query == state.query) return;
    final version = ++_queryVersion;
    emit(state.copyWith(query: event.query, listLoading: true));
    final result = await _listMine(query: event.query, size: pageSize);
    if (version != _queryVersion) return;
    emit(
      result.fold(
        (page) => state.copyWith(
          status: ChallengesListStatus.ready,
          challenges: page.items,
          page: page.page,
          hasMore: page.hasMore,
          listLoading: false,
          error: null,
        ),
        (error) => state.copyWith(
          status: ChallengesListStatus.failure,
          listLoading: false,
          error: error,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    ChallengesListLoadMoreRequested event,
    Emitter<ChallengesListState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore || state.listLoading) return;
    final version = _queryVersion;
    emit(state.copyWith(loadingMore: true));
    final result = await _listMine(
      query: state.query,
      page: state.page + 1,
      size: pageSize,
    );
    if (version != _queryVersion) return;
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
        _emitEffect(emit, ChallengesListEffect.failure(error));
    }
  }

  Future<void> _onPendingCompleted(
    ChallengesListPendingCompleted event,
    Emitter<ChallengesListState> emit,
  ) async {
    final milestoneId = event.pending.milestone.id;
    if (state.busyMilestoneIds.contains(milestoneId)) return;
    emit(
      state.copyWith(
        busyMilestoneIds: {...state.busyMilestoneIds, milestoneId},
      ),
    );
    final result = await _setMilestoneCompletion(
      event.pending.challengeId,
      milestoneId,
      completed: true,
    );
    final busy = {...state.busyMilestoneIds}..remove(milestoneId);
    switch (result) {
      case Success(:final value):
        final account = value.xpDelta != 0
            ? (await _getAccount()).valueOrNull
            : null;
        emit(
          state.copyWith(
            busyMilestoneIds: busy,
            pending: state.pending
                .where((p) => p.milestone.id != milestoneId)
                .toList(),
            challenges: [
              for (final c in state.challenges)
                c.id == value.challenge.id ? value.challenge : c,
            ],
          ),
        );
        _emitEffect(
          emit,
          ChallengesListEffect.milestoneCompleted(
            xpDelta: value.xpDelta,
            unlockedCount: value.unlockedMilestoneIds.length,
            challengeCompleted: value.challengeCompleted,
            account: account,
          ),
        );
        await _loadAll(emit);
      case Failure(:final error):
        emit(state.copyWith(busyMilestoneIds: busy));
        _emitEffect(emit, ChallengesListEffect.failure(error));
    }
  }

  void _emitEffect(
    Emitter<ChallengesListState> emit,
    ChallengesListEffect effect,
  ) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
