import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/enums/friendship_list_kind.dart';
import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/social_user.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/social/get_friendships_use_case.dart';
import '../../../../../../domain/use_cases/social/together/get_together_limits_use_case.dart';

part 'friend_picker_bloc.freezed.dart';
part 'friend_picker_event.dart';
part 'friend_picker_state.dart';

/// Lista de amigos mutuos para invitar (ADR 0044). El máximo de elegidos lo
/// manda el servidor (`GetTogetherLimitsUseCase`, ADR 0045) según a qué se
/// invita; una racha es con un solo amigo. Carga como mucho [maxPages] páginas:
/// nadie invita a más de 25.
class FriendPickerBloc extends Bloc<FriendPickerEvent, FriendPickerState> {
  FriendPickerBloc({required this._friendships, required this._limits})
    : super(const FriendPickerState()) {
    on<FriendPickerStarted>(_onStarted);
    on<FriendPickerToggled>(_onToggled);
  }

  static const maxPages = 4;
  static const _pageSize = 50;

  final GetFriendshipsUseCaseContract _friendships;
  final GetTogetherLimitsUseCaseContract _limits;

  Future<void> _onStarted(
    FriendPickerStarted event,
    Emitter<FriendPickerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FriendPickerStatus.loading,
        kind: event.kind,
        error: null,
      ),
    );
    TogetherLimits? limits;
    if (event.kind != TogetherInviteKind.streak) {
      switch (await _limits()) {
        case Success(:final value):
          limits = value;
        case Failure(:final error):
          emit(
            state.copyWith(status: FriendPickerStatus.failure, error: error),
          );
          return;
      }
    }
    final friends = <SocialUser>[];
    for (var page = 0; page < maxPages; page++) {
      final result = await _friendships(
        kind: FriendshipListKind.friends,
        page: page,
        size: _pageSize,
      );
      switch (result) {
        case Success(:final value):
          friends.addAll(value.items.map((f) => f.user));
          if (!value.hasMore) page = maxPages;
        case Failure(:final error):
          emit(
            state.copyWith(status: FriendPickerStatus.failure, error: error),
          );
          return;
      }
    }
    emit(
      state.copyWith(
        status: FriendPickerStatus.ready,
        friends: friends,
        limits: limits,
        max: limits?.friendsFor(event.kind) ?? 1,
      ),
    );
  }

  void _onToggled(FriendPickerToggled event, Emitter<FriendPickerState> emit) {
    final selected = [...state.selected];
    if (selected.contains(event.userId)) {
      selected.remove(event.userId);
    } else if (state.max == 1) {
      selected
        ..clear()
        ..add(event.userId);
    } else if (selected.length < state.max) {
      selected.add(event.userId);
    }
    emit(state.copyWith(selected: selected));
  }
}
