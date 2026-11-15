import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/social/together/decline_friend_challenge_use_case.dart';
import '../../../../../../domain/use_cases/social/together/get_friend_challenge_use_case.dart';
import '../../../../../../domain/use_cases/social/together/join_friend_challenge_use_case.dart';
import '../../../../../../domain/use_cases/social/together/leave_friend_challenge_use_case.dart';
import '../../../../../../domain/use_cases/social/together/react_to_friend_challenge_use_case.dart';
import '../../../../../../domain/use_cases/social/together/remove_friend_challenge_reaction_use_case.dart';

part 'friend_challenge_detail_bloc.freezed.dart';
part 'friend_challenge_detail_event.dart';
part 'friend_challenge_detail_state.dart';

/// Detalle de un reto con amigos (ADR 0044): aceptar o decir que no, salir en
/// un toque (con «Deshacer», que vuelve a entrar) y reaccionar en el tablón.
class FriendChallengeDetailBloc
    extends Bloc<FriendChallengeDetailEvent, FriendChallengeDetailState> {
  FriendChallengeDetailBloc({
    required this._get,
    required this._join,
    required this._decline,
    required this._leave,
    required this._react,
    required this._removeReaction,
  }) : super(const FriendChallengeDetailState()) {
    on<FriendChallengeDetailStarted>(_onStarted);
    on<FriendChallengeDetailJoined>(_onJoined);
    on<FriendChallengeDetailDeclined>(_onDeclined);
    on<FriendChallengeDetailLeft>(_onLeft);
    on<FriendChallengeDetailReactionTapped>(_onReaction);
  }

  final GetFriendChallengeUseCaseContract _get;
  final JoinFriendChallengeUseCaseContract _join;
  final DeclineFriendChallengeUseCaseContract _decline;
  final LeaveFriendChallengeUseCaseContract _leave;
  final ReactToFriendChallengeUseCaseContract _react;
  final RemoveFriendChallengeReactionUseCaseContract _removeReaction;

  String get _id => state.id!;

  Future<void> _onStarted(
    FriendChallengeDetailStarted event,
    Emitter<FriendChallengeDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        id: event.id,
        status: FriendChallengeDetailStatus.loading,
        error: null,
      ),
    );
    final result = await _get(event.id);
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: FriendChallengeDetailStatus.ready,
        challenge: value,
      ),
      Failure(:final error) => state.copyWith(
        status: FriendChallengeDetailStatus.failure,
        error: error,
      ),
    });
  }

  Future<void> _onJoined(
    FriendChallengeDetailJoined event,
    Emitter<FriendChallengeDetailState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _join(_id);
    emit(switch (result) {
      Success(:final value) => state.copyWith(busy: false, challenge: value),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(actionError: null));
  }

  Future<void> _onDeclined(
    FriendChallengeDetailDeclined event,
    Emitter<FriendChallengeDetailState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _decline(_id);
    emit(switch (result) {
      Success() => state.copyWith(
        busy: false,
        effect: FriendChallengeDetailEffect.declined,
      ),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(effect: null, actionError: null));
  }

  /// Sale ya (sin preguntar); el aviso trae «Deshacer», que vuelve a entrar.
  Future<void> _onLeft(
    FriendChallengeDetailLeft event,
    Emitter<FriendChallengeDetailState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _leave(_id);
    emit(switch (result) {
      Success() => state.copyWith(
        busy: false,
        effect: FriendChallengeDetailEffect.left,
      ),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(effect: null, actionError: null));
  }

  /// La misma reacción otra vez la quita; otra distinta la cambia.
  Future<void> _onReaction(
    FriendChallengeDetailReactionTapped event,
    Emitter<FriendChallengeDetailState> emit,
  ) async {
    if (state.busy) return;
    final entry = event.entry;
    emit(state.copyWith(busy: true));
    final result = entry.myReaction == event.reaction
        ? await _removeReaction(
            _id,
            recipientId: entry.person.id,
            day: entry.day,
          )
        : await _react(
            _id,
            recipientId: entry.person.id,
            day: entry.day,
            reaction: event.reaction,
          );
    if (result case Failure(:final error)) {
      emit(state.copyWith(busy: false, actionError: error));
      emit(state.copyWith(actionError: null));
      return;
    }
    final fresh = await _get(_id);
    emit(switch (fresh) {
      Success(:final value) => state.copyWith(busy: false, challenge: value),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(actionError: null));
  }
}
