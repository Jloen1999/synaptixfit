import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/enums/together_enums.dart';
import '../../../../../domain/enums/friendship_list_kind.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/progress/community_post_preview.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/social/friendship.dart';
import '../../../../../domain/models/social/together.dart';
import '../../../../../domain/use_cases/progress/get_community_preview_use_case.dart';
import '../../../../../domain/use_cases/social/accept_friend_request_use_case.dart';
import '../../../../../domain/use_cases/social/get_friendships_use_case.dart';
import '../../../../../domain/use_cases/social/reject_friend_request_use_case.dart';
import '../../../../../domain/use_cases/social/together/get_together_overview_use_case.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';
import '../../../social/feedback/social_feedback.dart';

part 'community_bloc.freezed.dart';
part 'community_event.dart';
part 'community_state.dart';

/// Tú › Comunidad (ADR 0061): reúne lo social que vivía en pantallas sueltas.
/// Lee en paralelo las solicitudes recibidas, los amigos, «Con amigos» y el
/// muro, y contesta solicitudes con los mismos casos de uso que Amigos. Lo
/// demás (buscar, el muro entero, cada reto o sala) se abre en su pantalla.
class CommunityBloc extends Bloc<CommunityEvent, CommunityState>
    with DataChangeRefreshMixin {
  CommunityBloc({
    required this._getFriendships,
    required this._acceptRequest,
    required this._rejectRequest,
    required this._getTogether,
    required this._getPosts,
    this._watchChanges,
  }) : super(const CommunityState()) {
    on<CommunityStarted>(_onStarted);
    on<CommunityRefreshed>((_, emit) => _load(emit));
    on<CommunityRequestAccepted>(
      (e, emit) => _answer(
        emit,
        e.friendshipId,
        () => _acceptRequest(friendshipId: e.friendshipId),
        SocialMessage.requestAccepted,
      ),
    );
    on<CommunityRequestRejected>(
      (e, emit) => _answer(
        emit,
        e.friendshipId,
        () => _rejectRequest(friendshipId: e.friendshipId),
        SocialMessage.requestRejected,
      ),
    );
  }

  final GetFriendshipsUseCaseContract _getFriendships;
  final AcceptFriendRequestUseCaseContract _acceptRequest;
  final RejectFriendRequestUseCaseContract _rejectRequest;
  final GetTogetherOverviewUseCaseContract _getTogether;
  final GetCommunityPreviewUseCaseContract _getPosts;
  final WatchDataChangesUseCaseContract? _watchChanges;

  /// Solicitudes que se contestan sin salir de la pestaña (una: un solo botón
  /// relleno en la pantalla); el resto, en Amigos › Recibidas («Ver las N»).
  static const requestsShown = 1;

  /// Publicaciones del muro que se adelantan.
  static const postsShown = 1;

  Future<void> _onStarted(
    CommunityStarted event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading, error: null));
    final watch = _watchChanges;
    if (watch != null) {
      // Solo lo social: las salas y los entrenos juntos cambian muy a menudo
      // y aquí basta con lo que se lee al entrar o al volver.
      watchDataChanges(
        watch,
        topics: const {DataTopic.social},
        onChanged: const CommunityEvent.refreshed(),
      );
    }
    await _load(emit);
  }

  Future<void> _load(Emitter<CommunityState> emit) async {
    final (requests, friends, together, posts) = await (
      _getFriendships(kind: FriendshipListKind.received, size: requestsShown),
      // Solo el total: la lista entera está en Amigos.
      _getFriendships(kind: FriendshipListKind.friends, size: 1),
      _getTogether(),
      _getPosts(size: postsShown),
    ).wait;
    switch ((requests, friends)) {
      case (Success(value: final r), Success(value: final f)):
        emit(
          state.copyWith(
            status: CommunityStatus.ready,
            error: null,
            requests: r.items,
            requestsTotal: r.totalItems,
            friendsTotal: f.totalItems,
            together: together.valueOrNull,
            posts: posts.valueOrNull,
          ),
        );
      case (Failure(:final error), _) || (_, Failure(:final error)):
        if (state.status == CommunityStatus.ready) {
          // Ya se veía: se conserva y solo se avisa.
          _notify(emit, state, SocialFeedback.error(error));
        } else {
          emit(state.copyWith(status: CommunityStatus.failure, error: error));
        }
    }
  }

  Future<void> _answer(
    Emitter<CommunityState> emit,
    String friendshipId,
    Future<AppResult<Friendship>> Function() action,
    SocialMessage message,
  ) async {
    if (state.busyIds.contains(friendshipId)) return;
    emit(state.copyWith(busyIds: {...state.busyIds, friendshipId}));
    final result = await action();
    final free = {...state.busyIds}..remove(friendshipId);
    switch (result) {
      case Success():
        _notify(
          emit,
          state.copyWith(
            busyIds: free,
            requests: [
              for (final r in state.requests)
                if (r.id != friendshipId) r,
            ],
            requestsTotal: state.requestsTotal > 0
                ? state.requestsTotal - 1
                : 0,
          ),
          SocialFeedback.message(message),
        );
        // La siguiente solicitud sube y el número de amigos cambia.
        await _load(emit);
      case Failure(:final error):
        _notify(
          emit,
          state.copyWith(busyIds: free),
          SocialFeedback.error(error),
        );
    }
  }

  /// Emite el aviso y lo limpia justo después: la página lo ve una sola vez.
  void _notify(
    Emitter<CommunityState> emit,
    CommunityState next,
    SocialFeedback feedback,
  ) {
    emit(next.copyWith(feedback: feedback));
    emit(state.copyWith(feedback: null));
  }
}
