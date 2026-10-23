import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/friendship_list_kind.dart';
import '../../../../../domain/enums/friendship_relation.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/social/friendship.dart';
import '../../../../../domain/models/social/user_card.dart';
import '../../../../../domain/use_cases/social/accept_friend_request_use_case.dart';
import '../../../../../domain/use_cases/social/get_friendships_use_case.dart';
import '../../../../../domain/use_cases/social/reject_friend_request_use_case.dart';
import '../../../../../domain/use_cases/social/remove_friendship_use_case.dart';
import '../../../../../domain/use_cases/social/search_users_use_case.dart';
import '../../../../../domain/use_cases/social/send_friend_request_use_case.dart';
import '../../widgets/social_feedback.dart';

part 'friends_bloc.freezed.dart';
part 'friends_event.dart';
part 'friends_state.dart';

/// Amistades (amigos, recibidas, enviadas, bloqueados) y búsqueda de usuarios.
class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  FriendsBloc({
    required this._getFriendships,
    required this._searchUsers,
    required this._sendRequest,
    required this._acceptRequest,
    required this._rejectRequest,
    required this._removeFriendship,
    this.searchDebounce = const Duration(milliseconds: 400),
    this.pageSize = 20,
  }) : super(const FriendsState()) {
    on<FriendsStarted>(_onStarted);
    on<FriendsSectionRefreshed>(_onSectionRefreshed);
    on<FriendsNextPageRequested>(_onNextPage);
    on<FriendsQueryChanged>(_onQueryChanged);
    on<FriendsRequestSent>(_onRequestSent);
    on<FriendsRequestAccepted>(_onAccepted);
    on<FriendsRequestRejected>(_onRejected);
    on<FriendsRemoved>(_onRemoved);
  }

  final GetFriendshipsUseCaseContract _getFriendships;
  final SearchUsersUseCaseContract _searchUsers;
  final SendFriendRequestUseCaseContract _sendRequest;
  final AcceptFriendRequestUseCaseContract _acceptRequest;
  final RejectFriendRequestUseCaseContract _rejectRequest;
  final RemoveFriendshipUseCaseContract _removeFriendship;

  /// Espera tras la última tecla antes de buscar.
  final Duration searchDebounce;
  final int pageSize;

  /// Mínimo de caracteres para buscar.
  static const minQueryLength = 2;

  Future<void> _onStarted(
    FriendsStarted event,
    Emitter<FriendsState> emit,
  ) async {
    await Future.wait(
      FriendshipListKind.values.map((kind) => _loadSection(emit, kind)),
    );
  }

  Future<void> _onSectionRefreshed(
    FriendsSectionRefreshed event,
    Emitter<FriendsState> emit,
  ) => _loadSection(emit, event.kind, keepItems: true);

  Future<void> _onNextPage(
    FriendsNextPageRequested event,
    Emitter<FriendsState> emit,
  ) async {
    final section = state.section(event.kind);
    if (!section.hasMore ||
        section.loadingMore ||
        section.status != SocialLoadStatus.loaded) {
      return;
    }
    emit(_withSection(event.kind, section.copyWith(loadingMore: true)));
    final result = await _getFriendships(
      kind: event.kind,
      page: section.page + 1,
      size: pageSize,
    );
    final current = state.section(event.kind);
    result.fold(
      (page) {
        final known = current.items.map((f) => f.id).toSet();
        emit(
          _withSection(
            event.kind,
            current.copyWith(
              loadingMore: false,
              items: [
                ...current.items,
                ...page.items.where((f) => !known.contains(f.id)),
              ],
              page: page.page,
              hasMore: page.hasMore,
            ),
          ),
        );
      },
      (error) => _notify(
        emit,
        _withSection(event.kind, current.copyWith(loadingMore: false)),
        SocialFeedback.error(error),
      ),
    );
  }

  /// Búsqueda con espera: solo se lanza si la consulta no cambia durante
  /// [searchDebounce], y se descarta la respuesta si ya hay otra consulta.
  Future<void> _onQueryChanged(
    FriendsQueryChanged event,
    Emitter<FriendsState> emit,
  ) async {
    final query = event.query.trim();
    if (query == state.query) return;
    if (query.length < minQueryLength) {
      emit(
        state.copyWith(
          query: query,
          searchStatus: UserSearchStatus.idle,
          results: const [],
          searchError: null,
        ),
      );
      return;
    }
    emit(state.copyWith(query: query));
    await Future<void>.delayed(searchDebounce);
    if (state.query != query) return;
    emit(state.copyWith(searchStatus: UserSearchStatus.loading));
    final result = await _searchUsers(query: query, size: pageSize);
    if (state.query != query) return;
    emit(
      result.fold(
        (page) => state.copyWith(
          searchStatus: UserSearchStatus.loaded,
          results: page.items,
          searchError: null,
        ),
        (error) => state.copyWith(
          searchStatus: UserSearchStatus.failure,
          searchError: error,
        ),
      ),
    );
  }

  Future<void> _onRequestSent(
    FriendsRequestSent event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.busyIds.contains(event.userId)) return;
    emit(_busy(event.userId, true));
    final result = await _sendRequest(userId: event.userId);
    result.fold(
      (friendship) {
        final sent = state.section(FriendshipListKind.sent);
        _notify(
          emit,
          _busy(event.userId, false).copyWith(
            results: [
              for (final u in state.results)
                u.id == event.userId
                    ? u.copyWith(
                        relation: friendship.relation,
                        friendshipId: friendship.id,
                      )
                    : u,
            ],
            sections: {
              ...state.sections,
              FriendshipListKind.sent: sent.copyWith(
                items: [
                  friendship,
                  ...sent.items.where((f) => f.id != friendship.id),
                ],
              ),
            },
          ),
          const SocialFeedback.message(SocialMessage.requestSent),
        );
      },
      (error) => _notify(
        emit,
        _busy(event.userId, false),
        SocialFeedback.error(error),
      ),
    );
  }

  Future<void> _onAccepted(
    FriendsRequestAccepted event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.busyIds.contains(event.friendshipId)) return;
    emit(_busy(event.friendshipId, true));
    final result = await _acceptRequest(friendshipId: event.friendshipId);
    if (result case Failure(:final error)) {
      _notify(
        emit,
        _busy(event.friendshipId, false),
        SocialFeedback.error(error),
      );
      return;
    }
    _notify(
      emit,
      _withoutFriendship(
        event.friendshipId,
        FriendshipRelation.friends,
      ).copyWith(busyIds: {...state.busyIds}..remove(event.friendshipId)),
      const SocialFeedback.message(SocialMessage.requestAccepted),
    );
    await _loadSection(emit, FriendshipListKind.friends, keepItems: true);
  }

  Future<void> _onRejected(
    FriendsRequestRejected event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.busyIds.contains(event.friendshipId)) return;
    emit(_busy(event.friendshipId, true));
    final result = await _rejectRequest(friendshipId: event.friendshipId);
    result.fold(
      (_) => _notify(
        emit,
        _withoutFriendship(
          event.friendshipId,
          FriendshipRelation.none,
        ).copyWith(busyIds: {...state.busyIds}..remove(event.friendshipId)),
        const SocialFeedback.message(SocialMessage.requestRejected),
      ),
      (error) => _notify(
        emit,
        _busy(event.friendshipId, false),
        SocialFeedback.error(error),
      ),
    );
  }

  /// Cancelar solicitud, eliminar amistad o desbloquear (mismo endpoint).
  Future<void> _onRemoved(
    FriendsRemoved event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.busyIds.contains(event.friendshipId)) return;
    emit(_busy(event.friendshipId, true));
    final result = await _removeFriendship(friendshipId: event.friendshipId);
    result.fold(
      (_) => _notify(
        emit,
        _withoutFriendship(
          event.friendshipId,
          FriendshipRelation.none,
        ).copyWith(busyIds: {...state.busyIds}..remove(event.friendshipId)),
        SocialFeedback.message(event.message),
      ),
      (error) => _notify(
        emit,
        _busy(event.friendshipId, false),
        SocialFeedback.error(error),
      ),
    );
  }

  Future<void> _loadSection(
    Emitter<FriendsState> emit,
    FriendshipListKind kind, {
    bool keepItems = false,
  }) async {
    final previous = state.section(kind);
    if (!keepItems || previous.status != SocialLoadStatus.loaded) {
      emit(_withSection(kind, const FriendsSection()));
    } else {
      emit(_withSection(kind, previous.copyWith(refreshing: true)));
    }
    final result = await _getFriendships(kind: kind, size: pageSize);
    emit(
      _withSection(
        kind,
        result.fold(
          (page) => FriendsSection(
            status: SocialLoadStatus.loaded,
            items: page.items,
            page: page.page,
            hasMore: page.hasMore,
          ),
          (error) =>
              FriendsSection(status: SocialLoadStatus.failure, error: error),
        ),
      ),
    );
  }

  FriendsState _withSection(FriendshipListKind kind, FriendsSection section) =>
      state.copyWith(sections: {...state.sections, kind: section});

  FriendsState _busy(String id, bool busy) => state.copyWith(
    busyIds: busy ? {...state.busyIds, id} : ({...state.busyIds}..remove(id)),
  );

  /// Quita la relación de todas las pestañas y actualiza la búsqueda.
  FriendsState _withoutFriendship(
    String friendshipId,
    FriendshipRelation newRelation,
  ) => state.copyWith(
    sections: {
      for (final entry in state.sections.entries)
        entry.key: entry.value.copyWith(
          items: entry.value.items.where((f) => f.id != friendshipId).toList(),
        ),
    },
    results: [
      for (final u in state.results)
        u.friendshipId == friendshipId
            ? u.copyWith(
                relation: newRelation,
                friendshipId: newRelation == FriendshipRelation.none
                    ? null
                    : u.friendshipId,
              )
            : u,
    ],
  );

  void _notify(
    Emitter<FriendsState> emit,
    FriendsState next,
    SocialFeedback feedback,
  ) {
    emit(next.copyWith(feedback: feedback));
    emit(next.copyWith(feedback: null));
  }
}
