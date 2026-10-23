import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/friendship_list_kind.dart';
import 'package:synaptixfit/domain/enums/friendship_relation.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/social/accept_friend_request_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/get_friendships_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/reject_friend_request_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/remove_friendship_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/search_users_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/send_friend_request_use_case.dart';
import 'package:synaptixfit/presentation/screens/social/friends/bloc/friends_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/widgets/social_feedback.dart';

import 'social_fixtures.dart';

class _GetFriendships extends Mock implements GetFriendshipsUseCaseContract {}

class _Search extends Mock implements SearchUsersUseCaseContract {}

class _Send extends Mock implements SendFriendRequestUseCaseContract {}

class _Accept extends Mock implements AcceptFriendRequestUseCaseContract {}

class _Reject extends Mock implements RejectFriendRequestUseCaseContract {}

class _Remove extends Mock implements RemoveFriendshipUseCaseContract {}

void main() {
  late _GetFriendships getFriendships;
  late _Search search;
  late _Send send;
  late _Accept accept;
  late _Reject reject;
  late _Remove remove;

  setUpAll(() => registerFallbackValue(FriendshipListKind.friends));

  setUp(() {
    getFriendships = _GetFriendships();
    search = _Search();
    send = _Send();
    accept = _Accept();
    reject = _Reject();
    remove = _Remove();
  });

  FriendsBloc build() => FriendsBloc(
    getFriendships: getFriendships,
    searchUsers: search,
    sendRequest: send,
    acceptRequest: accept,
    rejectRequest: reject,
    removeFriendship: remove,
    searchDebounce: Duration.zero,
  );

  void stubSection(FriendshipListKind kind, List<String> ids) =>
      when(
        () => getFriendships(
          kind: kind,
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async => Success(
          page([
            for (final id in ids) friendship(id, relation: relationOf(kind)),
          ]),
        ),
      );

  FriendsSection loadedSection(FriendshipListKind kind, List<String> ids) =>
      FriendsSection(
        status: SocialLoadStatus.loaded,
        items: [
          for (final id in ids) friendship(id, relation: relationOf(kind)),
        ],
      );

  final loaded = FriendsState(
    sections: {
      FriendshipListKind.friends: loadedSection(FriendshipListKind.friends, [
        'f1',
      ]),
      FriendshipListKind.received: loadedSection(FriendshipListKind.received, [
        'r1',
      ]),
      FriendshipListKind.sent: loadedSection(FriendshipListKind.sent, []),
      FriendshipListKind.blocked: loadedSection(FriendshipListKind.blocked, [
        'b1',
      ]),
    },
  );

  blocTest<FriendsBloc, FriendsState>(
    'carga las cuatro pestañas',
    setUp: () {
      stubSection(FriendshipListKind.friends, ['f1']);
      stubSection(FriendshipListKind.received, ['r1']);
      stubSection(FriendshipListKind.sent, []);
      stubSection(FriendshipListKind.blocked, ['b1']);
    },
    build: build,
    act: (bloc) => bloc.add(const FriendsEvent.started()),
    verify: (bloc) => expect(bloc.state, loaded),
  );

  blocTest<FriendsBloc, FriendsState>(
    'una pestaña que falla muestra su error sin afectar a las demás',
    setUp: () {
      stubSection(FriendshipListKind.friends, ['f1']);
      stubSection(FriendshipListKind.received, ['r1']);
      stubSection(FriendshipListKind.sent, []);
      when(
        () => getFriendships(
          kind: FriendshipListKind.blocked,
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => const Failure(AppError.network()));
    },
    build: build,
    act: (bloc) => bloc.add(const FriendsEvent.started()),
    verify: (bloc) {
      expect(
        bloc.state.section(FriendshipListKind.blocked),
        const FriendsSection(
          status: SocialLoadStatus.failure,
          error: AppError.network(),
        ),
      );
      expect(
        bloc.state.section(FriendshipListKind.friends).status,
        SocialLoadStatus.loaded,
      );
    },
  );

  blocTest<FriendsBloc, FriendsState>(
    'aceptar quita la solicitud de recibidas y recarga los amigos',
    setUp: () {
      when(
        () => accept(friendshipId: 'r1'),
      ).thenAnswer((_) async => Success(friendship('r1')));
      stubSection(FriendshipListKind.friends, ['f1', 'r1']);
    },
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const FriendsEvent.requestAccepted('r1')),
    verify: (bloc) {
      expect(bloc.state.section(FriendshipListKind.received).items, isEmpty);
      expect(
        bloc.state.section(FriendshipListKind.friends).items.map((f) => f.id),
        ['f1', 'r1'],
      );
      expect(bloc.state.busyIds, isEmpty);
    },
  );

  blocTest<FriendsBloc, FriendsState>(
    'desbloquear elimina la relación y confirma',
    setUp: () => when(
      () => remove(friendshipId: 'b1'),
    ).thenAnswer((_) async => const Success(unit)),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(
      const FriendsEvent.removed(
        friendshipId: 'b1',
        message: SocialMessage.userUnblocked,
      ),
    ),
    expect: () {
      final next = loaded.copyWith(
        sections: {
          ...loaded.sections,
          FriendshipListKind.blocked: loadedSection(
            FriendshipListKind.blocked,
            [],
          ),
        },
      );
      return [
        loaded.copyWith(busyIds: {'b1'}),
        next.copyWith(
          feedback: const SocialFeedback.message(SocialMessage.userUnblocked),
        ),
        next,
      ];
    },
  );

  blocTest<FriendsBloc, FriendsState>(
    'rechazar con error mantiene la solicitud y muestra el código de negocio',
    setUp: () => when(() => reject(friendshipId: 'r1')).thenAnswer(
      (_) async => const Failure(AppError.business('FRIENDSHIP_INVALID_STATE')),
    ),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const FriendsEvent.requestRejected('r1')),
    expect: () => [
      loaded.copyWith(busyIds: {'r1'}),
      loaded.copyWith(
        feedback: const SocialFeedback.error(
          AppError.business('FRIENDSHIP_INVALID_STATE'),
        ),
      ),
      loaded,
    ],
  );

  group('búsqueda', () {
    blocTest<FriendsBloc, FriendsState>(
      'no busca con menos de dos caracteres',
      build: build,
      act: (bloc) => bloc.add(const FriendsEvent.queryChanged('a')),
      expect: () => const [FriendsState(query: 'a')],
      verify: (_) => verifyNever(
        () => search(
          query: any(named: 'query'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ),
    );

    blocTest<FriendsBloc, FriendsState>(
      'busca tras la espera y muestra los resultados',
      setUp: () => when(
        () => search(
          query: 'ana',
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => Success(page([userCard('u9')]))),
      build: build,
      act: (bloc) => bloc.add(const FriendsEvent.queryChanged(' ana ')),
      expect: () => [
        const FriendsState(query: 'ana'),
        const FriendsState(
          query: 'ana',
          searchStatus: UserSearchStatus.loading,
        ),
        FriendsState(
          query: 'ana',
          searchStatus: UserSearchStatus.loaded,
          results: [userCard('u9')],
        ),
      ],
    );

    blocTest<FriendsBloc, FriendsState>(
      'descarta la búsqueda anterior si la consulta cambia (debounce)',
      setUp: () => when(
        () => search(
          query: any(named: 'query'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => Success(page([userCard('u9')]))),
      build: build,
      act: (bloc) => bloc
        ..add(const FriendsEvent.queryChanged('an'))
        ..add(const FriendsEvent.queryChanged('ana')),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        verifyNever(
          () => search(
            query: 'an',
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        );
        expect(bloc.state.results, [userCard('u9')]);
      },
    );

    blocTest<FriendsBloc, FriendsState>(
      'enviar solicitud desde la búsqueda actualiza la relación y enviadas',
      setUp: () => when(() => send(userId: 'u9')).thenAnswer(
        (_) async =>
            Success(friendship('s9', relation: FriendshipRelation.requestSent)),
      ),
      build: build,
      seed: () => loaded.copyWith(
        query: 'usu',
        searchStatus: UserSearchStatus.loaded,
        results: [userCard('u9')],
      ),
      act: (bloc) => bloc.add(const FriendsEvent.requestSent('u9')),
      verify: (bloc) {
        expect(
          bloc.state.results.single,
          userCard(
            'u9',
            relation: FriendshipRelation.requestSent,
            friendshipId: 's9',
          ),
        );
        expect(
          bloc.state.section(FriendshipListKind.sent).items.single.id,
          's9',
        );
      },
    );
  });
}
