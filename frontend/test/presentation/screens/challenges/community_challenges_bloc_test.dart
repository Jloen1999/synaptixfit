import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/enums/challenge_type.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_page.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/challenges/clone_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_community_challenges_use_case.dart';
import 'package:synaptixfit/presentation/screens/challenges/community_challenges/bloc/community_challenges_bloc.dart';

import '../data_changes_fake.dart';
import 'challenges_fixtures.dart';

class _MockCommunity extends Mock
    implements ListCommunityChallengesUseCaseContract {}

class _MockClone extends Mock implements CloneChallengeUseCaseContract {}

void main() {
  late _MockCommunity community;
  late _MockClone clone;
  late FakeDataChanges changes;
  final foreign = ChallengesFixtures.challenge(id: 'x1', owned: false);
  final copy = ChallengesFixtures.challenge(id: 'mine');
  final page = ChallengePage(
    items: [foreign],
    page: 0,
    totalPages: 1,
    totalItems: 1,
  );

  setUp(() {
    community = _MockCommunity();
    clone = _MockClone();
    changes = FakeDataChanges();
    when(
      () => community(
        type: any(named: 'type'),
        search: any(named: 'search'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => Success(page));
  });

  tearDown(() => changes.close());

  CommunityChallengesBloc build() => CommunityChallengesBloc(
    listCommunity: community,
    cloneChallenge: clone,
    watchChanges: changes.useCase,
  );

  blocTest<CommunityChallengesBloc, CommunityChallengesState>(
    'carga los retos de la comunidad',
    build: build,
    act: (b) => b.add(const CommunityChallengesEvent.started()),
    expect: () => [
      const CommunityChallengesState(),
      CommunityChallengesState(
        status: CommunityChallengesStatus.ready,
        challenges: [foreign],
      ),
    ],
  );

  blocTest<CommunityChallengesBloc, CommunityChallengesState>(
    'emite failure si falla la carga',
    setUp: () => when(
      () => community(
        type: any(named: 'type'),
        search: any(named: 'search'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => const Failure(AppError.server())),
    build: build,
    act: (b) => b.add(const CommunityChallengesEvent.started()),
    expect: () => [
      const CommunityChallengesState(),
      const CommunityChallengesState(
        status: CommunityChallengesStatus.failure,
        error: AppError.server(),
      ),
    ],
  );

  blocTest<CommunityChallengesBloc, CommunityChallengesState>(
    'filtrar por tipo vuelve a consultar con el filtro',
    build: build,
    seed: () =>
        const CommunityChallengesState(status: CommunityChallengesStatus.ready),
    act: (b) => b.add(
      const CommunityChallengesEvent.filtersChanged(
        type: ChallengeType.fitness,
      ),
    ),
    expect: () => [
      const CommunityChallengesState(
        status: CommunityChallengesStatus.ready,
        type: ChallengeType.fitness,
        listLoading: true,
      ),
      CommunityChallengesState(
        status: CommunityChallengesStatus.ready,
        type: ChallengeType.fitness,
        challenges: [foreign],
      ),
    ],
    verify: (_) => verify(
      () => community(type: ChallengeType.fitness, size: 20),
    ).called(1),
  );

  blocTest<CommunityChallengesBloc, CommunityChallengesState>(
    'clonar un reto emite el efecto con la copia',
    setUp: () => when(() => clone('x1')).thenAnswer((_) async => Success(copy)),
    build: build,
    seed: () => CommunityChallengesState(
      status: CommunityChallengesStatus.ready,
      challenges: [foreign],
    ),
    act: (b) => b.add(const CommunityChallengesEvent.cloneRequested('x1')),
    expect: () => [
      isA<CommunityChallengesState>().having((s) => s.cloningId, 'id', 'x1'),
      isA<CommunityChallengesState>().having((s) => s.cloningId, 'id', isNull),
      isA<CommunityChallengesState>().having(
        (s) => s.effect,
        'effect',
        CommunityChallengesEffect.cloned(copy),
      ),
      isA<CommunityChallengesState>().having((s) => s.effect, 'effect', isNull),
    ],
  );

  blocTest<CommunityChallengesBloc, CommunityChallengesState>(
    'un cambio de retos lo refresca en silencio',
    build: build,
    act: (bloc) async {
      bloc.add(const CommunityChallengesEvent.started());
      await pump();
      changes.emit({DataTopic.challenges});
      await pump();
    },
    verify: (_) => verify(
      () => community(
        type: any(named: 'type'),
        search: any(named: 'search'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).called(2),
  );

  blocTest<CommunityChallengesBloc, CommunityChallengesState>(
    'un cambio académico no lo refresca',
    build: build,
    act: (bloc) async {
      bloc.add(const CommunityChallengesEvent.started());
      await pump();
      changes.emit({DataTopic.academic});
      await pump();
    },
    verify: (_) => verify(
      () => community(
        type: any(named: 'type'),
        search: any(named: 'search'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).called(1),
  );
}
