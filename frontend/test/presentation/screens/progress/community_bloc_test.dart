import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/enums/friendship_list_kind.dart';
import 'package:synaptixfit/domain/enums/friendship_relation.dart';
import 'package:synaptixfit/domain/enums/together_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_community_preview_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/accept_friend_request_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/get_friendships_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/reject_friend_request_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/get_together_overview_use_case.dart';
import 'package:synaptixfit/domain/use_cases/sync/watch_data_changes_use_case.dart';
import 'package:synaptixfit/presentation/screens/progress/community/bloc/community_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/feedback/social_feedback.dart';

import '../social/social_fixtures.dart';

class _GetFriendships extends Mock implements GetFriendshipsUseCaseContract {}

class _Accept extends Mock implements AcceptFriendRequestUseCaseContract {}

class _Reject extends Mock implements RejectFriendRequestUseCaseContract {}

class _Together extends Mock implements GetTogetherOverviewUseCaseContract {}

class _Posts extends Mock implements GetCommunityPreviewUseCaseContract {}

class _Watch extends Mock implements WatchDataChangesUseCaseContract {}

/// Tú › Comunidad (ADR 0061): lee lo social en paralelo y contesta
/// solicitudes con los casos de uso de Amigos.
void main() {
  late _GetFriendships friendships;
  late _Accept accept;
  late _Reject reject;
  late _Together together;
  late _Posts posts;

  final request = friendship(
    'f1',
    relation: FriendshipRelation.requestReceived,
  );

  void stubRequests(List<String> ids, {int? total}) =>
      when(
        () => friendships(
          kind: FriendshipListKind.received,
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async => Success(
          page([
            for (final id in ids)
              friendship(id, relation: FriendshipRelation.requestReceived),
          ]).copyWith(totalItems: total ?? ids.length),
        ),
      );

  setUpAll(() => registerFallbackValue(<DataTopic>{}));

  setUp(() {
    friendships = _GetFriendships();
    accept = _Accept();
    reject = _Reject();
    together = _Together();
    posts = _Posts();
    stubRequests(['f1'], total: 3);
    when(
      () => friendships(
        kind: FriendshipListKind.friends,
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => Success(page([friendship('a1')]).copyWith(totalItems: 14)),
    );
    when(
      () => together(),
    ).thenAnswer((_) async => const Success(TogetherOverview()));
    when(
      () => posts(size: any(named: 'size')),
    ).thenAnswer((_) async => const Success([]));
  });

  CommunityBloc build({WatchDataChangesUseCaseContract? watch}) =>
      CommunityBloc(
        getFriendships: friendships,
        acceptRequest: accept,
        rejectRequest: reject,
        getTogether: together,
        getPosts: posts,
        watchChanges: watch,
      );

  blocTest<CommunityBloc, CommunityState>(
    'al empezar lee solicitudes, amigos, «Con amigos» y el muro',
    build: build,
    act: (bloc) => bloc.add(const CommunityEvent.started()),
    expect: () => [
      const CommunityState(),
      CommunityState(
        status: CommunityStatus.ready,
        requests: [request],
        requestsTotal: 3,
        friendsTotal: 14,
        together: const TogetherOverview(),
        posts: const [],
      ),
    ],
    verify: (_) {
      // Una sola solicitud a la vista: un solo botón relleno en la pantalla.
      verify(
        () => friendships(
          kind: FriendshipListKind.received,
          size: CommunityBloc.requestsShown,
        ),
      ).called(1);
    },
  );

  blocTest<CommunityBloc, CommunityState>(
    '«Con amigos» y el muro son opcionales: sin ellos la pestaña sale igual',
    setUp: () {
      when(
        () => together(),
      ).thenAnswer((_) async => const Failure(AppError.network()));
      when(
        () => posts(size: any(named: 'size')),
      ).thenAnswer((_) async => const Failure(AppError.server()));
    },
    build: build,
    act: (bloc) => bloc.add(const CommunityEvent.started()),
    expect: () => [
      const CommunityState(),
      isA<CommunityState>()
          .having((s) => s.status, 'status', CommunityStatus.ready)
          .having((s) => s.together, 'together', isNull)
          .having((s) => s.posts, 'posts', isNull),
    ],
  );

  blocTest<CommunityBloc, CommunityState>(
    'sin solicitudes ni amigos que leer, error con «Reintentar»',
    setUp: () => when(
      () => friendships(
        kind: FriendshipListKind.received,
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(const CommunityEvent.started()),
    expect: () => [
      const CommunityState(),
      const CommunityState(
        status: CommunityStatus.failure,
        error: AppError.network(),
      ),
    ],
  );

  blocTest<CommunityBloc, CommunityState>(
    'aceptar quita la solicitud, lo dice y vuelve a leer',
    setUp: () => when(
      () => accept(friendshipId: 'f1'),
    ).thenAnswer((_) async => Success(friendship('f1'))),
    build: build,
    seed: () => CommunityState(
      status: CommunityStatus.ready,
      requests: [request],
      requestsTotal: 1,
      friendsTotal: 13,
    ),
    act: (bloc) {
      stubRequests([]);
      bloc.add(const CommunityEvent.requestAccepted('f1'));
    },
    expect: () => [
      isA<CommunityState>().having((s) => s.busyIds, 'ocupada', {'f1'}),
      isA<CommunityState>()
          .having((s) => s.requests, 'requests', isEmpty)
          .having(
            (s) => s.feedback,
            'aviso',
            const SocialFeedback.message(SocialMessage.requestAccepted),
          ),
      isA<CommunityState>().having((s) => s.feedback, 'aviso', isNull),
      isA<CommunityState>()
          .having((s) => s.requestsTotal, 'requestsTotal', 0)
          .having((s) => s.friendsTotal, 'friendsTotal', 14),
    ],
  );

  blocTest<CommunityBloc, CommunityState>(
    'si rechazar falla, la solicitud sigue y se avisa del error',
    setUp: () => when(
      () => reject(friendshipId: 'f1'),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    seed: () => CommunityState(
      status: CommunityStatus.ready,
      requests: [request],
      requestsTotal: 1,
    ),
    act: (bloc) => bloc.add(const CommunityEvent.requestRejected('f1')),
    expect: () => [
      isA<CommunityState>().having((s) => s.busyIds, 'ocupada', {'f1'}),
      isA<CommunityState>()
          .having((s) => s.requests, 'requests', [request])
          .having((s) => s.busyIds, 'libre', isEmpty)
          .having(
            (s) => s.feedback,
            'aviso',
            const SocialFeedback.error(AppError.network()),
          ),
      isA<CommunityState>().having((s) => s.feedback, 'aviso', isNull),
    ],
  );

  test('se refresca sola con los cambios sociales', () async {
    final changes = StreamController<Set<DataTopic>>();
    addTearDown(changes.close);
    final watch = _Watch();
    when(
      () => watch(topics: any(named: 'topics')),
    ).thenAnswer((_) => changes.stream);
    final bloc = build(watch: watch)..add(const CommunityEvent.started());
    addTearDown(bloc.close);
    await bloc.stream.firstWhere((s) => s.status == CommunityStatus.ready);

    changes.add({DataTopic.social});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    verify(() => together()).called(2);
    verify(() => watch(topics: {DataTopic.social})).called(1);
  });

  group('«Con amigos ahora» (togetherNow)', () {
    StudyRoom room(String id, TogetherMemberStatus status) => StudyRoom(
      id: id,
      creator: const TogetherPerson(id: 'u3', name: 'Marta'),
      phase: StudyRoomPhase.focus,
      serverTime: DateTime(2026, 11, 20),
      myStatus: status,
    );

    test('sin «Con amigos» leído, no hay filas', () {
      expect(const CommunityState().togetherNow, isEmpty);
    });

    test('invitaciones primero, luego salas y rachas activas', () {
      final state = CommunityState(
        together: TogetherOverview(
          studyRooms: [
            room('r1', TogetherMemberStatus.invited),
            room('r2', TogetherMemberStatus.joined),
          ],
          streaks: const [
            FriendStreak(
              id: 's1',
              status: FriendStreakStatus.active,
              friend: TogetherPerson(id: 'u4'),
              days: 3,
            ),
            // Propuesta mía sin contestar: ni invitación ni «ahora».
            FriendStreak(
              id: 's2',
              status: FriendStreakStatus.pending,
              requestedByMe: true,
              friend: TogetherPerson(id: 'u5'),
            ),
          ],
        ),
      );

      final items = state.togetherNow;

      expect(items, hasLength(3));
      expect(
        items[0],
        isA<TogetherNowInvitations>().having((i) => i.count, 'count', 1),
      );
      expect(
        items[1],
        isA<TogetherNowStudyRoom>().having((i) => i.room.id, 'sala', 'r2'),
      );
      expect(
        items[2],
        isA<TogetherNowStreak>().having((i) => i.streak.id, 'racha', 's1'),
      );
    });
  });
}
