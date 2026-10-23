import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/enums/challenge_status.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_outcome.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_page.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_query.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_summary.dart';
import 'package:synaptixfit/domain/models/challenges/pending_milestone.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/get_challenge_summary_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_my_challenges_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_pending_milestones_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/set_milestone_completion_use_case.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenges_list/bloc/challenges_list_bloc.dart';

import '../data_changes_fake.dart';
import 'challenges_fixtures.dart';

class _MockList extends Mock implements ListMyChallengesUseCaseContract {}

class _MockSummary extends Mock implements GetChallengeSummaryUseCaseContract {}

class _MockPending extends Mock
    implements ListPendingMilestonesUseCaseContract {}

class _MockSetMilestone extends Mock
    implements SetMilestoneCompletionUseCaseContract {}

class _MockAccount extends Mock implements GetAccountUseCaseContract {}

void main() {
  late _MockList list;
  late _MockSummary summary;
  late _MockPending pending;
  late _MockSetMilestone setMilestone;
  late _MockAccount account;
  late FakeDataChanges changes;

  final c1 = ChallengesFixtures.challenge();
  final c2 = ChallengesFixtures.challenge(id: 'c2');
  final page0 = ChallengePage(
    items: [c1],
    page: 0,
    totalPages: 2,
    totalItems: 2,
  );
  final page1 = ChallengePage(
    items: [c2],
    page: 1,
    totalPages: 2,
    totalItems: 2,
  );
  const stats = ChallengeSummary(active: 2, completed: 1, expired: 0, total: 3);
  final pendingItem = PendingMilestone(
    challengeId: 'c1',
    challengeTitle: 'Reto c1',
    challengeEndAt: DateTime(2026, 10, 30),
    milestone: ChallengesFixtures.milestone('m1'),
  );

  void stubList(Result<ChallengePage, AppError> result, {int page = 0}) => when(
    () => list(
      query: any(named: 'query'),
      page: page,
      size: any(named: 'size'),
    ),
  ).thenAnswer((_) async => result);

  setUpAll(() => registerFallbackValue(const ChallengeQuery()));

  setUp(() {
    list = _MockList();
    summary = _MockSummary();
    pending = _MockPending();
    setMilestone = _MockSetMilestone();
    account = _MockAccount();
    changes = FakeDataChanges();
    when(() => summary()).thenAnswer((_) async => const Success(stats));
    when(() => pending()).thenAnswer((_) async => Success([pendingItem]));
  });

  ChallengesListBloc build() => ChallengesListBloc(
    listMine: list,
    summary: summary,
    pending: pending,
    setMilestoneCompletion: setMilestone,
    getAccount: account,
    watchChanges: changes.useCase,
  );

  blocTest<ChallengesListBloc, ChallengesListState>(
    'carga resumen, tareas pendientes y primera página',
    setUp: () => stubList(Success(page0)),
    build: build,
    act: (b) => b.add(const ChallengesListEvent.started()),
    expect: () => [
      const ChallengesListState(),
      ChallengesListState(
        status: ChallengesListStatus.ready,
        challenges: [c1],
        hasMore: true,
        summary: stats,
        pending: [pendingItem],
      ),
    ],
  );

  blocTest<ChallengesListBloc, ChallengesListState>(
    'emite failure si falla el listado',
    setUp: () => stubList(const Failure(AppError.network())),
    build: build,
    act: (b) => b.add(const ChallengesListEvent.started()),
    expect: () => [
      const ChallengesListState(),
      const ChallengesListState(
        status: ChallengesListStatus.failure,
        error: AppError.network(),
      ),
    ],
  );

  blocTest<ChallengesListBloc, ChallengesListState>(
    'cambiar filtros recarga con la nueva consulta',
    setUp: () => stubList(Success(page0)),
    build: build,
    seed: () => const ChallengesListState(status: ChallengesListStatus.ready),
    act: (b) => b.add(
      const ChallengesListEvent.queryChanged(
        ChallengeQuery(status: ChallengeStatus.completed),
      ),
    ),
    expect: () => [
      const ChallengesListState(
        status: ChallengesListStatus.ready,
        query: ChallengeQuery(status: ChallengeStatus.completed),
        listLoading: true,
      ),
      ChallengesListState(
        status: ChallengesListStatus.ready,
        query: const ChallengeQuery(status: ChallengeStatus.completed),
        challenges: [c1],
        hasMore: true,
      ),
    ],
    verify: (_) => verify(
      () => list(
        query: const ChallengeQuery(status: ChallengeStatus.completed),
        size: 20,
      ),
    ).called(1),
  );

  blocTest<ChallengesListBloc, ChallengesListState>(
    'carga la página siguiente y la añade',
    setUp: () => stubList(Success(page1), page: 1),
    build: build,
    seed: () => ChallengesListState(
      status: ChallengesListStatus.ready,
      challenges: [c1],
      hasMore: true,
    ),
    act: (b) => b.add(const ChallengesListEvent.loadMoreRequested()),
    expect: () => [
      ChallengesListState(
        status: ChallengesListStatus.ready,
        challenges: [c1],
        hasMore: true,
        loadingMore: true,
      ),
      ChallengesListState(
        status: ChallengesListStatus.ready,
        challenges: [c1, c2],
        page: 1,
      ),
    ],
  );

  blocTest<ChallengesListBloc, ChallengesListState>(
    'completar una tarea pendiente refresca la cuenta y avisa de la XP',
    setUp: () {
      stubList(Success(page0));
      when(() => setMilestone('c1', 'm1', completed: true)).thenAnswer(
        (_) async => Success(
          ChallengeOutcome(
            challenge: c1,
            xpDelta: 40,
            unlockedMilestoneIds: const ['m2'],
            challengeCompleted: false,
          ),
        ),
      );
      when(
        () => account(),
      ).thenAnswer((_) async => const Success(ChallengesFixtures.account));
    },
    build: build,
    seed: () => ChallengesListState(
      status: ChallengesListStatus.ready,
      pending: [pendingItem],
    ),
    act: (b) => b.add(ChallengesListEvent.pendingCompleted(pendingItem)),
    expect: () => [
      isA<ChallengesListState>().having((s) => s.busyMilestoneIds, 'busy', {
        'm1',
      }),
      isA<ChallengesListState>()
          .having((s) => s.busyMilestoneIds, 'busy', isEmpty)
          .having((s) => s.pending, 'pending', isEmpty),
      isA<ChallengesListState>().having(
        (s) => s.effect,
        'effect',
        const ChallengesListEffect.milestoneCompleted(
          xpDelta: 40,
          unlockedCount: 1,
          challengeCompleted: false,
          account: ChallengesFixtures.account,
        ),
      ),
      isA<ChallengesListState>().having((s) => s.effect, 'effect', isNull),
      isA<ChallengesListState>()
          .having((s) => s.challenges, 'challenges', [c1])
          .having((s) => s.summary, 'summary', stats),
    ],
  );

  blocTest<ChallengesListBloc, ChallengesListState>(
    'si completar falla emite el error como efecto',
    setUp: () =>
        when(() => setMilestone('c1', 'm1', completed: true)).thenAnswer(
          (_) async => const Failure(AppError.business('MILESTONE_LOCKED')),
        ),
    build: build,
    seed: () => ChallengesListState(
      status: ChallengesListStatus.ready,
      pending: [pendingItem],
    ),
    act: (b) => b.add(ChallengesListEvent.pendingCompleted(pendingItem)),
    skip: 2,
    expect: () => [
      isA<ChallengesListState>().having(
        (s) => s.effect,
        'effect',
        const ChallengesListEffect.failure(
          AppError.business('MILESTONE_LOCKED'),
        ),
      ),
      isA<ChallengesListState>().having((s) => s.effect, 'effect', isNull),
    ],
    verify: (_) => verifyNever(() => account()),
  );

  tearDown(() => changes.close());

  blocTest<ChallengesListBloc, ChallengesListState>(
    'un cambio de gamificación lo refresca en silencio',
    setUp: () => stubList(Success(page0)),
    build: build,
    act: (bloc) async {
      bloc.add(const ChallengesListEvent.started());
      await pump();
      changes.emit({DataTopic.gamification});
      await pump();
    },
    verify: (_) => verify(() => summary()).called(2),
  );

  blocTest<ChallengesListBloc, ChallengesListState>(
    'un cambio académico no lo refresca',
    setUp: () => stubList(Success(page0)),
    build: build,
    act: (bloc) async {
      bloc.add(const ChallengesListEvent.started());
      await pump();
      changes.emit({DataTopic.academic});
      await pump();
    },
    verify: (_) => verify(() => summary()).called(1),
  );
}
