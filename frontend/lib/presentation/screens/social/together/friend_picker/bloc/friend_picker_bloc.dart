import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/enums/friendship_list_kind.dart';
import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/social_user.dart';
import '../../../../../../domain/use_cases/social/get_friendships_use_case.dart';

part 'friend_picker_bloc.freezed.dart';
part 'friend_picker_event.dart';
part 'friend_picker_state.dart';

/// Lista de amigos mutuos para invitar (ADR 0044), con un máximo de elegidos.
/// Carga como mucho [maxPages] páginas: nadie invita a más de 25.
class FriendPickerBloc extends Bloc<FriendPickerEvent, FriendPickerState> {
  FriendPickerBloc({required this._friendships})
    : super(const FriendPickerState()) {
    on<FriendPickerStarted>(_onStarted);
    on<FriendPickerToggled>(_onToggled);
  }

  static const maxPages = 4;
  static const _pageSize = 50;

  final GetFriendshipsUseCaseContract _friendships;

  Future<void> _onStarted(
    FriendPickerStarted event,
    Emitter<FriendPickerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FriendPickerStatus.loading,
        max: event.max,
        error: null,
      ),
    );
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
    emit(state.copyWith(status: FriendPickerStatus.ready, friends: friends));
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
