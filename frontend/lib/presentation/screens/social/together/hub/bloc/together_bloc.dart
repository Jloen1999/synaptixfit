import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/result/app_result.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/social/together/accept_friend_streak_use_case.dart';
import '../../../../../../domain/use_cases/social/together/decline_friend_challenge_use_case.dart';
import '../../../../../../domain/use_cases/social/together/decline_friend_streak_use_case.dart';
import '../../../../../../domain/use_cases/social/together/decline_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together/end_friend_streak_use_case.dart';
import '../../../../../../domain/use_cases/social/together/get_together_overview_use_case.dart';
import '../../../../../../domain/use_cases/social/together/join_friend_challenge_use_case.dart';
import '../../../../../../domain/use_cases/social/together/join_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together/nudge_friend_streak_use_case.dart';
import '../../../../../../domain/use_cases/social/together/propose_friend_streak_use_case.dart';

part 'together_bloc.freezed.dart';
part 'together_event.dart';
part 'together_state.dart';

/// Pantalla «Con amigos» (ADR 0044): invitaciones, retos, rachas y entrenos de
/// hoy. Cada acción va al servidor y después se vuelve a leer todo (lo que se
/// ve lo calcula siempre el servidor).
class TogetherBloc extends Bloc<TogetherEvent, TogetherState> {
  TogetherBloc({
    required this._overview,
    required this._joinChallenge,
    required this._declineChallenge,
    required this._proposeStreak,
    required this._acceptStreak,
    required this._declineStreak,
    required this._endStreak,
    required this._nudgeStreak,
    required this._joinWorkout,
    required this._declineWorkout,
  }) : super(const TogetherState()) {
    on<TogetherStarted>(_onStarted);
    on<TogetherRefreshed>(_onRefreshed);
    on<TogetherChallengeJoined>(
      (e, emit) => _act(emit, e.id, () => _joinChallenge(e.id), null),
    );
    on<TogetherChallengeDeclined>(
      (e, emit) => _act(
        emit,
        e.id,
        () => _declineChallenge(e.id),
        TogetherMessage.declined,
      ),
    );
    on<TogetherStreakProposed>(
      (e, emit) => _act(
        emit,
        e.friendId,
        () => _proposeStreak(e.friendId),
        TogetherMessage.streakProposed,
      ),
    );
    on<TogetherStreakAccepted>(
      (e, emit) => _act(
        emit,
        e.id,
        () => _acceptStreak(e.id),
        TogetherMessage.streakAccepted,
      ),
    );
    on<TogetherStreakDeclined>(
      (e, emit) => _act(
        emit,
        e.id,
        () => _declineStreak(e.id),
        TogetherMessage.declined,
      ),
    );
    on<TogetherStreakEnded>(
      (e, emit) =>
          _act(emit, e.id, () => _endStreak(e.id), TogetherMessage.streakEnded),
    );
    on<TogetherStreakWithdrawn>(
      (e, emit) => _act(
        emit,
        e.id,
        () => _endStreak(e.id),
        TogetherMessage.streakWithdrawn,
      ),
    );
    on<TogetherStreakNudged>(
      (e, emit) => _act(
        emit,
        e.id,
        () => _nudgeStreak(e.id),
        TogetherMessage.streakNudged,
      ),
    );
    on<TogetherWorkoutJoined>(
      (e, emit) => _act(emit, e.id, () => _joinWorkout(e.id), null),
    );
    on<TogetherWorkoutDeclined>(
      (e, emit) => _act(
        emit,
        e.id,
        () => _declineWorkout(e.id),
        TogetherMessage.declined,
      ),
    );
  }

  final GetTogetherOverviewUseCaseContract _overview;
  final JoinFriendChallengeUseCaseContract _joinChallenge;
  final DeclineFriendChallengeUseCaseContract _declineChallenge;
  final ProposeFriendStreakUseCaseContract _proposeStreak;
  final AcceptFriendStreakUseCaseContract _acceptStreak;
  final DeclineFriendStreakUseCaseContract _declineStreak;
  final EndFriendStreakUseCaseContract _endStreak;
  final NudgeFriendStreakUseCaseContract _nudgeStreak;
  final JoinWorkoutTogetherUseCaseContract _joinWorkout;
  final DeclineWorkoutTogetherUseCaseContract _declineWorkout;

  Future<void> _onStarted(
    TogetherStarted event,
    Emitter<TogetherState> emit,
  ) async {
    emit(state.copyWith(status: TogetherStatus.loading, error: null));
    await _load(emit);
  }

  Future<void> _onRefreshed(
    TogetherRefreshed event,
    Emitter<TogetherState> emit,
  ) => _load(emit);

  Future<void> _load(Emitter<TogetherState> emit) async {
    final result = await _overview();
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: TogetherStatus.ready,
        overview: value,
      ),
      Failure(:final error) =>
        state.status == TogetherStatus.ready
            ? state.copyWith(actionError: error)
            : state.copyWith(status: TogetherStatus.failure, error: error),
    });
    emit(state.copyWith(actionError: null));
  }

  Future<void> _act<T>(
    Emitter<TogetherState> emit,
    String busyId,
    Future<AppResult<T>> Function() action,
    TogetherMessage? message,
  ) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: busyId));
    final result = await action();
    switch (result) {
      case Success():
        emit(state.copyWith(busyId: null, message: message));
        emit(state.copyWith(message: null));
        await _load(emit);
      case Failure(:final error):
        emit(state.copyWith(busyId: null, actionError: error));
        emit(state.copyWith(actionError: null));
    }
  }
}
