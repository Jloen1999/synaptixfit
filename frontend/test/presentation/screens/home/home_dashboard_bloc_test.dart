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
import 'package:synaptixfit/domain/use_cases/planner/delete_block_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/reschedule_block_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/cancel_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/finish_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/log_past_session_use_case.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/use_cases/planner/set_block_completion_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/set_deadline_completion_use_case.dart';
import 'package:synaptixfit/domain/models/planner/deadline.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
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

class _MockCompleteDeadline extends Mock
    implements SetDeadlineCompletionUseCaseContract {}

class _MockReschedule extends Mock implements RescheduleBlockUseCaseContract {}

class _MockDeleteBlock extends Mock implements DeleteBlockUseCaseContract {}

class _MockFinish extends Mock implements FinishSessionUseCaseContract {}

class _MockCancel extends Mock implements CancelSessionUseCaseContract {}

class _MockLogPast extends Mock implements LogPastSessionUseCaseContract {}

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
  late _MockCompleteDeadline completeDeadline;
  late _MockReschedule reschedule;
  late _MockPermissionsIntro permissionsIntro;
  late _MockDeleteBlock deleteBlock;
  late _MockFinish finish;
  late _MockCancel cancel;
  late _MockLogPast logPast;

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
    setDeadlineCompletion: completeDeadline,
    permissionsIntroPending: permissionsIntro,
    finishSession: finish,
    cancelSession: cancel,
    logPastSession: logPast,
    rescheduleBlock: reschedule,
    deleteBlock: deleteBlock,
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
    completeDeadline = _MockCompleteDeadline();
    reschedule = _MockReschedule();
    permissionsIntro = _MockPermissionsIntro();
    deleteBlock = _MockDeleteBlock();
    finish = _MockFinish();
    cancel = _MockCancel();
    logPast = _MockLogPast();
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
    '«Ahora no» se guarda con la cuenta aunque la política aún no esté '
    'comprobada (antes iba con un id vacío y al recargar volvía)',
    setUp: () {
      registerFallbackValue(DateTime(2026));
      when(
        () => snooze(any(), userId: any(named: 'userId')),
      ).thenAnswer((_) async => Success(DateTime(2026, 10, 27, 9)));
    },
    build: build,
    act: (bloc) async {
      bloc.add(
        const HomeDashboardEvent.started(userId: 'u1', checkOnboarding: false),
      );
      await bloc.stream.firstWhere(
        (s) => s.status == HomeDashboardStatus.loaded,
      );
      bloc.add(const HomeDashboardEvent.setupSnoozed());
    },
    skip: 1,
    verify: (_) {
      verify(() => getSetup(userId: 'u1')).called(1);
      verify(() => snooze(any(), userId: 'u1')).called(1);
      verifyNever(() => getOnboarding());
    },
  );

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'una recarga que leyó antes del «Ahora no» no vuelve a enseñar el aviso',
    setUp: () => when(() => getSetup(userId: any(named: 'userId'))).thenAnswer(
      (_) async => const Success(
        HomeSetup(pending: [HomeSetupTask.subjects], total: 3),
      ),
    ),
    build: build,
    seed: () => loaded.copyWith(
      setup: HomeSetup(
        pending: const [HomeSetupTask.subjects],
        total: 3,
        snoozedUntil: DateTime(2026, 10, 27, 9),
      ),
    ),
    act: (bloc) => bloc.add(const HomeDashboardEvent.refreshed()),
    skip: 1,
    expect: () => [
      loaded.copyWith(
        setup: HomeSetup(
          pending: const [HomeSetupTask.subjects],
          total: 3,
          snoozedUntil: DateTime(2026, 10, 27, 9),
        ),
      ),
    ],
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

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    'con una sesión a medias, «Empezar» lleva a su tarjeta en vez de un aviso '
    'sin salida (ADR 0059)',
    setUp: () => when(() => start(routineId: 'r1', dayId: 'd1')).thenAnswer(
      (_) async => const Failure(AppError.business('SESSION_STALE_OPEN')),
    ),
    build: build,
    act: (bloc) => bloc.add(
      const HomeDashboardEvent.trainingStarted(routineId: 'r1', dayId: 'd1'),
    ),
    expect: () => [
      const HomeDashboardState(startingTraining: true),
      const HomeDashboardState(showUnfinished: true),
      // Vuelve a leer Inicio: la tarjeta «Sin terminar» sale con sus botones.
      loaded.copyWith(showUnfinished: true),
    ],
  );

  group('sesión a medias (ADR 0059)', () {
    blocTest<HomeDashboardBloc, HomeDashboardState>(
      '«Guardar lo hecho» la termina con los minutos y el esfuerzo elegidos',
      setUp: () =>
          when(() => finish('s9', durationSeconds: 2700, rpe: 6)).thenAnswer(
            (_) async => Success(
              FinishSessionResult(
                session: TrainingFixtures.session(
                  status: SessionStatus.completed,
                ),
                experience: const ExperienceChange(
                  level: 1,
                  levelXp: 10,
                  xpDelta: 10,
                ),
              ),
            ),
          ),
      build: build,
      act: (bloc) => bloc.add(
        const HomeDashboardEvent.unfinishedSaved(
          sessionId: 's9',
          minutes: 45,
          rpe: 6,
        ),
      ),
      expect: () => const [
        HomeDashboardState(actingIds: {'s9'}),
        HomeDashboardState(actionNotice: HomeActionNotice.sessionSaved()),
      ],
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      '«Descartar» la quita ya y solo la borra al cerrarse el aviso',
      setUp: () =>
          when(() => cancel('s9')).thenAnswer((_) async => const Success(unit)),
      build: build,
      act: (bloc) => bloc
        ..add(const HomeDashboardEvent.unfinishedDiscarded('s9'))
        ..add(const HomeDashboardEvent.actionNoticeHandled())
        ..add(const HomeDashboardEvent.deferredCommitted('session:s9')),
      expect: () => const [
        HomeDashboardState(
          deferredKeys: {'session:s9'},
          actionNotice: HomeActionNotice.sessionDiscarded('session:s9'),
        ),
        HomeDashboardState(deferredKeys: {'session:s9'}),
      ],
      verify: (_) => verify(() => cancel('s9')).called(1),
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      '«Deshacer» la vuelve a enseñar y no se borra nada',
      build: build,
      act: (bloc) => bloc
        ..add(const HomeDashboardEvent.unfinishedDiscarded('s9'))
        ..add(const HomeDashboardEvent.actionNoticeHandled())
        ..add(const HomeDashboardEvent.deferredUndone('session:s9'))
        // El aviso se cierra después: ya no hay nada que hacer.
        ..add(const HomeDashboardEvent.deferredCommitted('session:s9')),
      expect: () => const [
        HomeDashboardState(
          deferredKeys: {'session:s9'},
          actionNotice: HomeActionNotice.sessionDiscarded('session:s9'),
        ),
        HomeDashboardState(deferredKeys: {'session:s9'}),
        HomeDashboardState(),
      ],
      verify: (_) => verifyNever(() => cancel(any())),
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      'si no se puede descartar, vuelve a verse y se avisa',
      setUp: () => when(
        () => cancel('s9'),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      act: (bloc) => bloc
        ..add(const HomeDashboardEvent.unfinishedDiscarded('s9'))
        ..add(const HomeDashboardEvent.actionNoticeHandled())
        ..add(const HomeDashboardEvent.deferredCommitted('session:s9')),
      expect: () => const [
        HomeDashboardState(
          deferredKeys: {'session:s9'},
          actionNotice: HomeActionNotice.sessionDiscarded('session:s9'),
        ),
        HomeDashboardState(deferredKeys: {'session:s9'}),
        HomeDashboardState(
          actionNotice: HomeActionNotice.failed(AppError.network()),
        ),
      ],
    );
  });

  blocTest<HomeDashboardBloc, HomeDashboardState>(
    '«Empezar» con un descarte aún por confirmar lo borra antes de empezar',
    setUp: () {
      when(() => cancel('s9')).thenAnswer((_) async => const Success(unit));
      when(
        () => start(routineId: 'r1', dayId: 'd1'),
      ).thenAnswer((_) async => Success(TrainingFixtures.session()));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const HomeDashboardEvent.unfinishedDiscarded('s9'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const HomeDashboardEvent.trainingStarted(routineId: 'r1', dayId: 'd1'),
      );
      await Future<void>.delayed(Duration.zero);
      // El aviso se cierra después: no se borra dos veces.
      bloc.add(const HomeDashboardEvent.deferredCommitted('session:s9'));
    },
    verify: (_) {
      verify(() => cancel('s9')).called(1);
      verify(() => start(routineId: 'r1', dayId: 'd1')).called(1);
    },
  );

  group('lo de ayer sin marcar (ADR 0059)', () {
    final moved = block(id: 'b9', start: DateTime(2026, 10, 22, 19));

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      '«Pasar a otro día» lo lleva al día elegido y dice a cuál',
      setUp: () => when(
        () => reschedule(
          'b9',
          start: DateTime(2026, 10, 22, 19),
          end: DateTime(2026, 10, 22, 20),
        ),
      ).thenAnswer((_) async => Success(BlockChange(block: moved))),
      build: build,
      act: (bloc) => bloc.add(
        HomeDashboardEvent.missedMoved(
          eventId: 'b9',
          start: DateTime(2026, 10, 22, 19),
          end: DateTime(2026, 10, 22, 20),
        ),
      ),
      expect: () => [
        const HomeDashboardState(actingIds: {'b9'}),
        HomeDashboardState(
          actionNotice: HomeActionNotice.moved(DateTime(2026, 10, 22, 19)),
        ),
      ],
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      '«Quitar» lo borra del calendario al cerrarse su «Deshacer»',
      setUp: () => when(
        () => deleteBlock('b9'),
      ).thenAnswer((_) async => const Success(unit)),
      build: build,
      act: (bloc) => bloc
        ..add(const HomeDashboardEvent.missedRemoved('b9'))
        ..add(const HomeDashboardEvent.actionNoticeHandled())
        ..add(const HomeDashboardEvent.deferredCommitted('block:b9')),
      expect: () => const [
        HomeDashboardState(
          deferredKeys: {'block:b9'},
          actionNotice: HomeActionNotice.removed('block:b9'),
        ),
        HomeDashboardState(deferredKeys: {'block:b9'}),
      ],
      verify: (_) => verify(() => deleteBlock('b9')).called(1),
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      'al cerrar Inicio con un «Quitar» pendiente, se borra igual',
      setUp: () => when(
        () => deleteBlock('b9'),
      ).thenAnswer((_) async => const Success(unit)),
      build: build,
      act: (bloc) async {
        bloc.add(const HomeDashboardEvent.missedRemoved('b9'));
        await Future<void>.delayed(Duration.zero);
        await bloc.close();
      },
      verify: (_) => verify(() => deleteBlock('b9')).called(1),
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      '«Lo hice» de un día de rutina lo apunta como sesión de ese día',
      setUp: () =>
          when(
            () => logPast(
              routineId: 'r1',
              dayId: 'd1',
              date: DateTime(2026, 10, 19),
              durationMinutes: 50,
              rpe: 7,
            ),
          ).thenAnswer(
            (_) async => Success(
              PastSessionResult(
                session: TrainingFixtures.session(
                  status: SessionStatus.completed,
                ),
                experience: const ExperienceChange(
                  level: 1,
                  levelXp: 10,
                  xpDelta: 10,
                ),
              ),
            ),
          ),
      build: build,
      act: (bloc) => bloc.add(
        HomeDashboardEvent.missedLogged(
          eventId: 'b9',
          routineId: 'r1',
          dayId: 'd1',
          date: DateTime(2026, 10, 19),
          minutes: 50,
          rpe: 7,
        ),
      ),
      expect: () => const [
        HomeDashboardState(actingIds: {'b9'}),
        HomeDashboardState(actionNotice: HomeActionNotice.logged()),
      ],
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      '«Lo hice» de un estudio lo marca y deja de pedirse',
      setUp: () => when(() => complete('m1', completed: true)).thenAnswer(
        (_) async => Success(
          BlockCompletion(
            block: block(
              id: 'm1',
              start: DateTime(2026, 10, 19, 19),
            ).copyWith(completed: true, timeStatus: ItemTimeStatus.done),
            xpDelta: 10,
          ),
        ),
      ),
      build: build,
      seed: () => loaded.copyWith(
        dashboard: homeDashboardFixture.copyWith(
          missedEvents: [
            HomeTodayEvent(
              id: 'm1',
              kind: HomeEventKind.block,
              type: HomeEventType.study,
              title: 'Repasar Cálculo',
              start: DateTime(2026, 10, 19, 19),
              end: DateTime(2026, 10, 19, 20),
              completed: false,
              status: ItemTimeStatus.missed,
            ),
          ],
        ),
      ),
      act: (bloc) => bloc.add(
        const HomeDashboardEvent.completionSet(
          id: 'm1',
          kind: HomeEventKind.block,
          completed: true,
        ),
      ),
      verify: (bloc) {
        final missed = bloc.state.dashboard!.missedEvents.single;
        expect(missed.completed, isTrue);
      },
    );
  });

  group('marcar desde la agenda (ADR 0035)', () {
    final event = HomeTodayEvent(
      id: 'b1',
      kind: HomeEventKind.block,
      type: HomeEventType.personal,
      title: 'Dentista',
      start: DateTime(2026, 10, 20, 8),
      completed: false,
      status: ItemTimeStatus.missed,
    );
    final withEvent = loaded.copyWith(
      dashboard: homeDashboardFixture.copyWith(todayEvents: [event]),
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      'marca el evento con el estado del servidor y ofrece deshacer',
      setUp: () => when(() => complete('b1', completed: true)).thenAnswer(
        (_) async => Success(
          BlockCompletion(
            block: block(
              id: 'b1',
              start: DateTime(2026, 10, 20, 8),
            ).copyWith(completed: true, timeStatus: ItemTimeStatus.done),
            xpDelta: 0,
          ),
        ),
      ),
      build: build,
      seed: () => withEvent,
      act: (bloc) => bloc.add(
        const HomeDashboardEvent.completionSet(
          id: 'b1',
          kind: HomeEventKind.block,
          completed: true,
        ),
      ),
      expect: () => [
        withEvent.copyWith(completingIds: {'b1'}),
        withEvent.copyWith(
          dashboard: homeDashboardFixture.copyWith(
            todayEvents: [
              event.copyWith(completed: true, status: ItemTimeStatus.done),
            ],
          ),
          completionNotice: const HomeCompletionNotice.done(
            id: 'b1',
            kind: HomeEventKind.block,
            completed: true,
            xpDelta: 0,
          ),
          // Ctrl+Z puede deshacerlo.
          lastUndoable: const HomeCompletionNoticeDone(
            id: 'b1',
            kind: HomeEventKind.block,
            completed: true,
            xpDelta: 0,
          ),
        ),
      ],
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      'Ctrl+Z deshace lo último marcado y no se puede deshacer dos veces',
      setUp: () => when(() => complete('b1', completed: false)).thenAnswer(
        (_) async => Success(
          BlockCompletion(
            block: block(id: 'b1', start: DateTime(2026, 10, 20, 8)),
            xpDelta: 0,
          ),
        ),
      ),
      build: build,
      seed: () => withEvent.copyWith(
        lastUndoable: const HomeCompletionNoticeDone(
          id: 'b1',
          kind: HomeEventKind.block,
          completed: true,
          xpDelta: 0,
        ),
      ),
      act: (bloc) => bloc
        ..add(const HomeDashboardEvent.undoRequested())
        ..add(const HomeDashboardEvent.undoRequested()),
      verify: (bloc) {
        verify(() => complete('b1', completed: false)).called(1);
        expect(bloc.state.lastUndoable, isNull);
      },
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      'desmarcar una entrega devuelve la XP que dio',
      setUp: () =>
          when(() => completeDeadline('d1', completed: false)).thenAnswer(
            (_) async =>
                Success(DeadlineCompletion(deadline: deadline(), xpDelta: -25)),
          ),
      build: build,
      act: (bloc) => bloc.add(
        const HomeDashboardEvent.completionSet(
          id: 'd1',
          kind: HomeEventKind.deadline,
          completed: false,
        ),
      ),
      verify: (bloc) => expect(
        bloc.state.completionNotice,
        const HomeCompletionNotice.done(
          id: 'd1',
          kind: HomeEventKind.deadline,
          completed: false,
          xpDelta: -25,
        ),
      ),
    );

    blocTest<HomeDashboardBloc, HomeDashboardState>(
      'si falla, avisa con el error y no cambia nada',
      setUp: () => when(
        () => complete('b1', completed: true),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      seed: () => withEvent,
      act: (bloc) => bloc.add(
        const HomeDashboardEvent.completionSet(
          id: 'b1',
          kind: HomeEventKind.block,
          completed: true,
        ),
      ),
      expect: () => [
        withEvent.copyWith(completingIds: {'b1'}),
        withEvent.copyWith(
          completionNotice: const HomeCompletionNotice.failed(
            AppError.network(),
          ),
        ),
      ],
    );
  });
}
