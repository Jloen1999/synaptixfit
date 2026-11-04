import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/domain/models/home/home_onboarding_status.dart';
import 'package:synaptixfit/domain/models/home/home_setup.dart';
import 'package:synaptixfit/domain/models/planner/weekly_planning.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/home/get_home_dashboard_use_case.dart';
import 'package:synaptixfit/domain/use_cases/home/get_home_due_reviews_use_case.dart';
import 'package:synaptixfit/domain/use_cases/home/get_home_onboarding_status_use_case.dart';
import 'package:synaptixfit/domain/use_cases/home/get_home_setup_use_case.dart';
import 'package:synaptixfit/domain/use_cases/home/snooze_home_setup_use_case.dart';
import 'package:synaptixfit/domain/use_cases/home/get_home_unread_count_use_case.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_timeline_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/is_permissions_intro_pending_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/reschedule_block_to_next_free_slot_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/set_block_completion_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/start_session_use_case.dart';
import 'package:synaptixfit/presentation/screens/home/dashboard/bloc/home_dashboard_bloc.dart';
import 'package:synaptixfit/presentation/screens/home/home_onboarding_gate.dart';

import '../data_changes_fake.dart';
import '../planner/planner_fixtures.dart';
import '../training/training_fixtures.dart';
import 'home_fixtures.dart';

class _MockDashboard extends Mock implements GetHomeDashboardUseCaseContract {}

class _MockReviews extends Mock implements GetHomeDueReviewsUseCaseContract {}

class _MockUnread extends Mock implements GetHomeUnreadCountUseCaseContract {}

class _MockOnboarding extends Mock
    implements GetHomeOnboardingStatusUseCaseContract {}

class _MockTimeline extends Mock implements GetTimelineUseCaseContract {}

class _MockStart extends Mock implements StartSessionUseCaseContract {}

class _MockSetup extends Mock implements GetHomeSetupUseCaseContract {}

class _MockSnooze extends Mock implements SnoozeHomeSetupUseCaseContract {}

class _MockComplete extends Mock implements SetBlockCompletionUseCaseContract {}

class _MockReschedule extends Mock
    implements RescheduleBlockToNextFreeSlotUseCaseContract {}

class _MockPermissionsIntro extends Mock
    implements IsPermissionsIntroPendingUseCaseContract {}

void main() {
  late _MockDashboard getDashboard;
  late _MockReviews getReviews;
  late _MockUnread getUnread;
  late _MockOnboarding getOnboarding;
  late _MockTimeline getTimeline;
  late HomeOnboardingGate gate;
  late FakeDataChanges changes;
  late _MockStart start;
  late _MockSetup getSetup;
  late _MockSnooze snooze;
  late _MockComplete complete;
  late _MockReschedule reschedule;
  late _MockPermissionsIntro permissionsIntro;

  HomeDashboardBloc build() => HomeDashboardBloc(
    getDashboard: getDashboard,
    getDueReviews: getReviews,
    getUnreadCount: getUnread,
    getOnboardingStatus: getOnboarding,
    getSetup: getSetup,
    snoozeSetup: snooze,
    getTimeline: getTimeline,
    onboardingGate: gate,
    watchChanges: changes.useCase,
    startSession: start,
    setBlockCompletion: complete,
    rescheduleToNextSlot: reschedule,
    permissionsIntroPending: permissionsIntro,
    clock: () => DateTime(2026, 10, 20, 9),
  );

  final loaded = HomeDashboardState(
    status: HomeDashboardStatus.loaded,
    dashboard: homeDashboardFixture,
    dueReviews: homeReviewsFixture,
    unreadNotifications: 3,
    setup: const HomeSetup(),
  );

  setUp(() {
    start = _MockStart();
    getSetup = _MockSetup();
    snooze = _MockSnooze();
    complete = _MockComplete();
    reschedule = _MockReschedule();
    permissionsIntro = _MockPermissionsIntro();
    when(
      () => permissionsIntro(),
    ).thenAnswer((_) async => const Success(false));
    when(
      () => getSetup(userId: any(named: 'userId')),
    ).thenAnswer((_) async => const Success(HomeSetup()));
    getDashboard = _MockDashboard();
    getReviews = _MockReviews();
    getUnread = _MockUnread();
    getOnboarding = _MockOnboarding();
    getTimeline = _MockTimeline();
    gate = HomeOnboardingGate();
    changes = FakeDataChanges();

    when(
      () => getDashboard(),
    ).thenAnswer((_) async => Success(homeDashboardFixture));
    when(
      () => getReviews(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Success(homeReviewsFixture));
    when(() => getUnread()).thenAnswer((_) async => const Success(3));
    when(
      () => getTimeline(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => const Success(<TimelineEntry>[]));
    when(() => getOnboarding()).thenAnswer(
      (_) async => const Success(HomeOnboardingStatus(completed: true)),
    );
  });

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    '«Ahora no» oculta el aviso de configuración una semana',
    setUp: () {
      registerFallbackValue(DateTime(2026));
      when(
        () => snooze(any(), userId: any(named: 'userId')),
      ).thenAnswer((_) async => Success(DateTime(2026, 10, 27, 9)));
    },
    build: build,
    seed: () => loaded.copyWith(
      setup: const HomeSetup(pending: [HomeSetupTask.subjects], total: 3),
    ),
    act: (bloc) => bloc.add(const HomeDashboardEvent.setupSnoozed()),
    expect: () => [
      loaded.copyWith(
        setup: HomeSetup(
          pending: const [HomeSetupTask.subjects],
          total: 3,
          snoozedUntil: DateTime(2026, 10, 27, 9),
        ),
      ),
    ],
    verify: (_) => verify(
      () => snooze(DateTime(2026, 10, 20, 9), userId: any(named: 'userId')),
    ).called(1),
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'carga el resumen, los repasos y el contador',
    build: build,
    act: (bloc) => bloc.add(const HomeDashboardEvent.started(userId: 'u1')),
    expect: () => [loaded],
    verify: (_) =>
        verify(() => getReviews(limit: HomeDashboardBloc.dueReviewsLimit)),
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'trae la agenda de mañana a seis días después y la convierte en eventos',
    setUp: () =>
        when(
          () => getTimeline(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer(
          (_) async => Success([
            TimelineEntry(
              kind: TimelineKind.block,
              id: 'b1',
              blockType: BlockType.sport,
              title: 'Pierna',
              start: DateTime(2026, 10, 21, 18),
              end: DateTime(2026, 10, 21, 19),
            ),
            TimelineEntry(
              kind: TimelineKind.deadline,
              id: 'd1',
              deadlineType: DeadlineType.exam,
              start: DateTime(2026, 10, 23, 10),
              subjectName: 'Cálculo',
            ),
          ]),
        ),
    build: build,
    act: (bloc) => bloc.add(const HomeDashboardEvent.started(userId: 'u1')),
    expect: () => [
      loaded.copyWith(
        upcoming: [
          HomeTodayEvent(
            id: 'b1',
            kind: HomeEventKind.block,
            type: HomeEventType.sport,
            title: 'Pierna',
            start: DateTime(2026, 10, 21, 18),
            end: DateTime(2026, 10, 21, 19),
            completed: false,
          ),
          HomeTodayEvent(
            id: 'd1',
            kind: HomeEventKind.deadline,
            type: HomeEventType.exam,
            title: 'Cálculo',
            start: DateTime(2026, 10, 23, 10),
            completed: false,
            subjectName: 'Cálculo',
          ),
        ],
      ),
    ],
    verify: (_) => verify(
      () =>
          getTimeline(from: DateTime(2026, 10, 21), to: DateTime(2026, 10, 27)),
    ),
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'si el resumen falla emite failure con el error',
    setUp: () => when(
      () => getDashboard(),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(const HomeDashboardEvent.started(userId: 'u1')),
    expect: () => const [
      HomeDashboardState(
        status: HomeDashboardStatus.failure,
        error: AppError.network(),
      ),
    ],
    verify: (_) => verifyNever(() => getOnboarding()),
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'los repasos, el contador y el aviso de configuración son opcionales',
    setUp: () {
      when(
        () => getReviews(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Failure(AppError.server()));
      when(
        () => getUnread(),
      ).thenAnswer((_) async => const Failure(AppError.server()));
      when(
        () => getSetup(userId: 'u1'),
      ).thenAnswer((_) async => const Failure(AppError.server()));
    },
    build: build,
    act: (bloc) => bloc.add(const HomeDashboardEvent.started(userId: 'u1')),
    expect: () => [
      HomeDashboardState(
        status: HomeDashboardStatus.loaded,
        dashboard: homeDashboardFixture,
      ),
    ],
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'redirige al onboarding si no está completado',
    setUp: () => when(() => getOnboarding()).thenAnswer(
      (_) async => const Success(HomeOnboardingStatus(completed: false)),
    ),
    build: build,
    act: (bloc) async {
      bloc.add(const HomeDashboardEvent.started(userId: 'u1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const HomeDashboardEvent.onboardingHandled());
    },
    expect: () => [loaded, loaded.copyWith(onboardingRequired: true), loaded],
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'con el onboarding hecho, abre una vez el paso «Permisos» si está pendiente',
    setUp: () => when(
      () => permissionsIntro(),
    ).thenAnswer((_) async => const Success(true)),
    build: build,
    act: (bloc) async {
      bloc.add(const HomeDashboardEvent.started(userId: 'u1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const HomeDashboardEvent.permissionsIntroHandled());
    },
    expect: () => [
      loaded,
      loaded.copyWith(permissionsIntroRequired: true),
      loaded,
    ],
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'con el onboarding pendiente no abre los permisos (van al terminarlo)',
    setUp: () {
      when(() => getOnboarding()).thenAnswer(
        (_) async => const Success(HomeOnboardingStatus(completed: false)),
      );
      when(
        () => permissionsIntro(),
      ).thenAnswer((_) async => const Success(true));
    },
    build: build,
    act: (bloc) => bloc.add(const HomeDashboardEvent.started(userId: 'u1')),
    expect: () => [loaded, loaded.copyWith(onboardingRequired: true)],
    verify: (_) => verifyNever(() => permissionsIntro()),
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'comprueba el onboarding solo una vez por usuario y sesión',
    setUp: () {
      gate.shouldCheck('u1');
      when(() => getOnboarding()).thenAnswer(
        (_) async => const Success(HomeOnboardingStatus(completed: false)),
      );
    },
    build: build,
    act: (bloc) => bloc.add(const HomeDashboardEvent.started(userId: 'u1')),
    expect: () => [loaded],
    verify: (_) => verifyNever(() => getOnboarding()),
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'al refrescar con error conserva los datos y expone el error',
    seed: () => loaded,
    setUp: () => when(
      () => getDashboard(),
    ).thenAnswer((_) async => const Failure(AppError.server())),
    build: build,
    act: (bloc) => bloc.add(const HomeDashboardEvent.refreshed()),
    expect: () => [
      loaded.copyWith(refreshing: true),
      loaded.copyWith(error: const AppError.server()),
    ],
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'reintentar tras un error vuelve a cargar desde cero',
    seed: () => const HomeDashboardState(
      status: HomeDashboardStatus.failure,
      error: AppError.network(),
    ),
    build: build,
    act: (bloc) => bloc.add(const HomeDashboardEvent.refreshed()),
    expect: () => [const HomeDashboardState(), loaded],
  );

  tearDown(() => changes.close());

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'un cambio de datos de cualquier módulo lo refresca en silencio',
    build: build,
    act: (bloc) async {
      bloc.add(const HomeDashboardEvent.started(userId: 'u1'));
      await pump();
      changes.emit({DataTopic.challenges});
      await pump();
    },
    expect: () => [loaded, loaded.copyWith(refreshing: true), loaded],
    verify: (_) => verify(() => getDashboard()).called(2),
  );

  test('al cerrarse deja de escuchar los cambios de datos', () async {
    final bloc = build()..add(const HomeDashboardEvent.started(userId: 'u1'));
    await pump();
    await bloc.close();
    changes.emit({DataTopic.training});
    await pump();
    verify(() => getDashboard()).called(1);
  });

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    '«Empezar» crea o recupera la sesión del día y pide abrirla',
    setUp: () => when(
      () => start(routineId: 'r1', dayId: 'd1'),
    ).thenAnswer((_) async => Success(TrainingFixtures.session())),
    build: build,
    act: (bloc) => bloc
      ..add(
        const HomeDashboardEvent.trainingStarted(routineId: 'r1', dayId: 'd1'),
      )
      ..add(const HomeDashboardEvent.trainingHandled()),
    expect: () => const [
      HomeDashboardState(startingTraining: true),
      HomeDashboardState(openSessionId: 's1'),
      HomeDashboardState(),
    ],
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'si no se puede empezar, se avisa del error',
    setUp: () => when(
      () => start(routineId: 'r1', dayId: 'd1'),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(
      const HomeDashboardEvent.trainingStarted(routineId: 'r1', dayId: 'd1'),
    ),
    expect: () => const [
      HomeDashboardState(startingTraining: true),
      HomeDashboardState(trainingError: AppError.network()),
    ],
  );

  group('acciones del aviso de bloques sin hacer', () {
    final missed = block(id: 'b9', start: DateTime(2026, 10, 20, 8));

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      '«Hecho» marca el bloque y avisa de la XP que dio el servidor',
      setUp: () => when(() => complete('b9', completed: true)).thenAnswer(
        (_) async => Success(BlockCompletion(block: missed, xpDelta: 20)),
      ),
      build: build,
      act: (bloc) => bloc
        ..add(const HomeDashboardEvent.bannerBlockCompleted('b9'))
        ..add(const HomeDashboardEvent.bannerNoticeHandled()),
      expect: () => const [
        HomeDashboardState(bannerBusy: HomeBannerAction.complete),
        HomeDashboardState(bannerNotice: HomeBannerNotice.completed(20)),
        HomeDashboardState(),
      ],
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      '«Al próximo hueco» lo mueve y dice a dónde',
      setUp: () => when(
        () => reschedule('b9'),
      ).thenAnswer((_) async => Success(BlockChange(block: missed))),
      build: build,
      act: (bloc) =>
          bloc.add(const HomeDashboardEvent.bannerBlockRescheduled('b9')),
      expect: () => [
        const HomeDashboardState(bannerBusy: HomeBannerAction.reschedule),
        HomeDashboardState(
          bannerNotice: HomeBannerNotice.rescheduled(DateTime(2026, 10, 20, 8)),
        ),
      ],
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      'si falla, avisa con el error',
      setUp: () => when(
        () => reschedule('b9'),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      act: (bloc) =>
          bloc.add(const HomeDashboardEvent.bannerBlockRescheduled('b9')),
      expect: () => const [
        HomeDashboardState(bannerBusy: HomeBannerAction.reschedule),
        HomeDashboardState(
          bannerNotice: HomeBannerNotice.failed(AppError.network()),
        ),
      ],
    );
  });
}
