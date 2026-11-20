import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/domain/models/planner/weekly_planning.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/delete_block_use_case.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/models/planner/planner_options.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_planner_challenges_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/start_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_timeline_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_week_balance_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_week_blocks_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_week_conflicts_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/reschedule_block_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/set_block_completion_use_case.dart';
import 'package:synaptixfit/presentation/screens/planner/calendar/bloc/calendar_bloc.dart';

import 'planner_fixtures.dart';
import '../data_changes_fake.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';

class _Blocks extends Mock implements GetWeekBlocksUseCaseContract {}

class _Conflicts extends Mock implements GetWeekConflictsUseCaseContract {}

class _Timeline extends Mock implements GetTimelineUseCaseContract {}

class _Balance extends Mock implements GetWeekBalanceUseCaseContract {}

class _Reschedule extends Mock implements RescheduleBlockUseCaseContract {}

class _Completion extends Mock implements SetBlockCompletionUseCaseContract {}

class _Account extends Mock implements GetAccountUseCaseContract {}

class _DeleteBlock extends Mock implements DeleteBlockUseCaseContract {}

class _Challenges extends Mock implements GetPlannerChallengesUseCaseContract {}

class _StartSession extends Mock implements StartSessionUseCaseContract {}

void main() {
  setUpAll(registerPlannerFallbacks);

  late _Blocks getBlocks;
  late _Conflicts getConflicts;
  late _Timeline getTimeline;
  late _Balance getBalance;
  late _Reschedule reschedule;
  late _Completion setCompletion;
  late FakeDataChanges changes;
  late _Account getAccount;
  late _DeleteBlock deleteBlock;
  late _Challenges getChallenges;
  late _StartSession startSession;

  final b1 = block();
  final deadlineEntry = TimelineEntry(
    kind: TimelineKind.deadline,
    id: 'd1',
    title: 'Práctica',
    start: DateTime(2025, 10, 17, 23),
  );
  final blockEntry = TimelineEntry(
    kind: TimelineKind.block,
    id: 'b1',
    subjectName: 'Cálculo',
    start: b1.start,
  );

  CalendarBloc build() => CalendarBloc(
    getBlocks: getBlocks,
    getConflicts: getConflicts,
    getTimeline: getTimeline,
    getBalance: getBalance,
    reschedule: reschedule,
    setCompletion: setCompletion,
    getAccount: getAccount,
    deleteBlock: deleteBlock,
    getChallenges: getChallenges,
    startSession: startSession,
    watchChanges: changes.useCase,
    now: () => testNow,
  );

  CalendarState ready() => CalendarState(
    weekStart: testMonday,
    status: CalendarStatus.ready,
    blocks: [b1],
    balance: testBalance,
  );

  setUp(() {
    getBlocks = _Blocks();
    getConflicts = _Conflicts();
    getTimeline = _Timeline();
    getBalance = _Balance();
    reschedule = _Reschedule();
    setCompletion = _Completion();
    changes = FakeDataChanges();
    getAccount = _Account();
    deleteBlock = _DeleteBlock();
    getChallenges = _Challenges();
    startSession = _StartSession();
    when(() => deleteBlock(any())).thenAnswer((_) async => const Success(unit));
    when(() => getBlocks(any())).thenAnswer((_) async => Success([b1]));
    when(() => getConflicts(any())).thenAnswer((_) async => const Success([]));
    when(
      () => getTimeline(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => Success([deadlineEntry, blockEntry]));
    when(() => getBalance(any())).thenAnswer((_) async => Success(testBalance));
    when(
      () => getAccount(),
    ).thenAnswer((_) async => const Success(testAccount));
  });

  blocTest<CalendarBloc, CalendarState>(
    'carga la semana actual con bloques, entregas, títulos y balance',
    build: build,
    act: (bloc) => bloc.add(const CalendarEvent.started()),
    expect: () => [
      isA<CalendarState>().having(
        (s) => s.status,
        'status',
        CalendarStatus.loading,
      ),
      isA<CalendarState>()
          .having((s) => s.status, 'status', CalendarStatus.ready)
          .having((s) => s.weekStart, 'weekStart', testMonday)
          .having((s) => s.blocks, 'blocks', [b1])
          .having((s) => s.deadlines, 'deadlines', [deadlineEntry])
          .having((s) => s.blockTitles, 'titles', {'b1': 'Cálculo'})
          .having((s) => s.blockSubjects, 'asignaturas', {'b1': 'Cálculo'})
          .having((s) => s.balance, 'balance', testBalance),
    ],
    verify: (_) {
      verify(() => getBlocks(testMonday)).called(1);
      // Sin eventos con reto no se piden los retos.
      verifyNever(() => getChallenges());
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'con un evento que adelanta un reto, pide los retos una vez y nombra la tarea',
    setUp: () {
      when(() => getBlocks(any())).thenAnswer(
        (_) async => Success([b1.copyWith(challengeId: 'c1', milestoneId: 't2')]),
      );
      when(() => getChallenges()).thenAnswer(
        (_) async => const Success([
          ChallengeOption(
            id: 'c1',
            title: 'Estudia y muévete',
            tasks: [
              ChallengeTaskOption(id: 't1', title: 'Día 1'),
              ChallengeTaskOption(id: 't2', title: 'Día 2'),
            ],
          ),
        ]),
      );
    },
    build: build,
    act: (bloc) async {
      bloc.add(const CalendarEvent.started());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const CalendarEvent.refreshed());
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      verify(() => getChallenges()).called(1);
      expect(bloc.state.challengeOf(bloc.state.blocks.single), (
        challenge: 'Estudia y muévete',
        task: 'Día 2',
      ));
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'si fallan los bloques muestra el error',
    setUp: () => when(
      () => getBlocks(any()),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(const CalendarEvent.started()),
    skip: 1,
    expect: () => [
      isA<CalendarState>()
          .having((s) => s.status, 'status', CalendarStatus.failure)
          .having((s) => s.error, 'error', const AppError.network()),
    ],
  );

  blocTest<CalendarBloc, CalendarState>(
    'navegar a la semana siguiente carga ese lunes',
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(const CalendarEvent.weekShifted(1)),
    verify: (bloc) {
      expect(bloc.state.weekStart, DateTime(2025, 10, 20));
      verify(() => getBlocks(DateTime(2025, 10, 20))).called(1);
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'tocar una franja pasada avisa; una futura abre el editor',
    build: build,
    seed: ready,
    act: (bloc) => bloc
      ..add(CalendarEvent.slotTapped(DateTime(2025, 10, 15, 8)))
      ..add(CalendarEvent.slotTapped(DateTime(2025, 10, 16, 8))),
    expect: () => [
      isA<CalendarState>().having(
        (s) => s.notice,
        'notice',
        const CalendarNotice.inPast(),
      ),
      isA<CalendarState>().having(
        (s) => s.notice,
        'notice',
        CalendarNotice.createAt(DateTime(2025, 10, 16, 8)),
      ),
    ],
  );

  group('mover bloques', () {
    final newStart = DateTime(2025, 10, 17, 11);
    final newEnd = DateTime(2025, 10, 17, 12);
    final moved = b1.copyWith(start: newStart, end: newEnd);

    blocTest<CalendarBloc, CalendarState>(
      'actualiza en optimista, confirma y avisa de solapes',
      setUp: () =>
          when(
            () => reschedule(
              'b1',
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenAnswer(
            (_) async => Success(
              BlockChange(
                block: moved,
                conflicts: [block(id: 'b2')],
              ),
            ),
          ),
      build: build,
      seed: ready,
      act: (bloc) => bloc.add(
        CalendarEvent.blockRescheduled(
          blockId: 'b1',
          start: newStart,
          end: newEnd,
        ),
      ),
      expect: () => [
        isA<CalendarState>()
            .having((s) => s.blocks.single.start, 'start', newStart)
            .having((s) => s.busyBlockIds, 'busy', {'b1'}),
        isA<CalendarState>()
            .having((s) => s.blocks.single, 'block', moved)
            .having((s) => s.busyBlockIds, 'busy', isEmpty),
        isA<CalendarState>().having(
          (s) => s.notice,
          'notice',
          const CalendarNotice.overlaps(1),
        ),
      ],
      verify: (_) => verify(() => getConflicts(testMonday)).called(1),
    );

    blocTest<CalendarBloc, CalendarState>(
      'si la API falla vuelve a la posición original',
      setUp: () =>
          when(
            () => reschedule(
              'b1',
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenAnswer(
            (_) async => const Failure(AppError.business('BLOCK_IN_PAST')),
          ),
      build: build,
      seed: ready,
      act: (bloc) => bloc.add(
        CalendarEvent.blockRescheduled(
          blockId: 'b1',
          start: newStart,
          end: newEnd,
        ),
      ),
      skip: 1,
      expect: () => [
        isA<CalendarState>()
            .having((s) => s.blocks.single, 'block', b1)
            .having(
              (s) => s.notice,
              'notice',
              const CalendarNotice.failure(AppError.business('BLOCK_IN_PAST')),
            ),
      ],
    );

    blocTest<CalendarBloc, CalendarState>(
      'no mueve bloques fijos ni al pasado',
      build: build,
      seed: () => ready().copyWith(
        blocks: [
          b1,
          block(id: 'fixed', fixed: true),
        ],
      ),
      act: (bloc) => bloc
        ..add(
          CalendarEvent.blockRescheduled(
            blockId: 'fixed',
            start: newStart,
            end: newEnd,
          ),
        )
        ..add(
          CalendarEvent.blockRescheduled(
            blockId: 'b1',
            start: DateTime(2025, 10, 14, 9),
            end: DateTime(2025, 10, 14, 10),
          ),
        ),
      expect: () => [
        isA<CalendarState>().having(
          (s) => s.notice,
          'notice',
          const CalendarNotice.blockLocked(),
        ),
        isA<CalendarState>().having(
          (s) => s.notice,
          'notice',
          const CalendarNotice.inPast(),
        ),
      ],
      verify: (_) => verifyNever(
        () => reschedule(
          any(),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ),
    );
  });

  blocTest<CalendarBloc, CalendarState>(
    'completar un bloque da XP y refresca la cuenta',
    setUp: () => when(() => setCompletion('b1', completed: true)).thenAnswer(
      (_) async => Success(
        BlockCompletion(block: b1.copyWith(completed: true), xpDelta: 20),
      ),
    ),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(const CalendarEvent.completionToggled('b1')),
    skip: 1,
    expect: () => [
      isA<CalendarState>()
          .having((s) => s.blocks.single.completed, 'completed', isTrue)
          .having(
            (s) => s.notice,
            'notice',
            const CalendarNotice.blockXp(
              completed: true,
              xpDelta: 20,
              account: testAccount,
            ),
          ),
    ],
    verify: (_) => verify(() => getAccount()).called(1),
  );

  blocTest<CalendarBloc, CalendarState>(
    '«No fui» en una clase aún sin dar por asistida la desmarca y avisa',
    setUp: () => when(() => setCompletion('b1', completed: false)).thenAnswer(
      (_) async => Success(
        BlockCompletion(
          block: b1.copyWith(type: BlockType.classSession, absent: true),
          xpDelta: 0,
        ),
      ),
    ),
    build: build,
    seed: ready,
    act: (bloc) =>
        bloc.add(const CalendarEvent.completionToggled('b1', completed: false)),
    skip: 1,
    expect: () => [
      isA<CalendarState>()
          .having((s) => s.blocks.single.absent, 'ausente', isTrue)
          .having(
            (s) => s.notice,
            'notice',
            const CalendarNotice.blockXp(
              completed: false,
              xpDelta: 0,
              absent: true,
            ),
          ),
    ],
    verify: (_) => verifyNever(
      () => setCompletion('b1', completed: true, effort: any(named: 'effort')),
    ),
  );

  blocTest<CalendarBloc, CalendarState>(
    'es una pestaña: se recarga sola cuando otra pantalla cambia el planificador',
    build: build,
    act: (bloc) async {
      bloc.add(const CalendarEvent.started());
      await pump();
      await pump();
      changes.emit({DataTopic.planner});
      await pump();
      await pump();
    },
    verify: (_) => verify(() => getBlocks(testMonday)).called(2),
  );

  group('borrar con deshacer', () {
    blocTest<CalendarBloc, CalendarState>(
      'el bloque desaparece ya y se borra cuando el aviso se cierra sin deshacer',
      build: build,
      seed: ready,
      act: (bloc) async {
        bloc.add(CalendarEvent.blockDeleteRequested(b1));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.visibleBlocks, isEmpty);
        expect(bloc.state.notice, CalendarNotice.blockDeleted(b1.id));
        verifyNever(() => deleteBlock(any()));
        bloc.add(CalendarEvent.blockDeleteCommitted(b1.id));
      },
      verify: (bloc) {
        verify(() => deleteBlock(b1.id)).called(1);
        expect(bloc.state.pendingDeletionIds, isEmpty);
      },
    );

    blocTest<CalendarBloc, CalendarState>(
      '«Deshacer» lo devuelve y un cierre posterior del aviso ya no borra',
      build: build,
      seed: ready,
      act: (bloc) => bloc
        ..add(CalendarEvent.blockDeleteRequested(b1))
        ..add(CalendarEvent.blockDeleteUndone(b1.id))
        ..add(CalendarEvent.blockDeleteCommitted(b1.id)),
      verify: (bloc) {
        verifyNever(() => deleteBlock(any()));
        expect(bloc.state.visibleBlocks, [b1]);
      },
    );

    blocTest<CalendarBloc, CalendarState>(
      'si el servidor no lo borra, vuelve a verse y se avisa',
      setUp: () => when(
        () => deleteBlock(any()),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      seed: ready,
      act: (bloc) => bloc
        ..add(CalendarEvent.blockDeleteRequested(b1))
        ..add(CalendarEvent.blockDeleteCommitted(b1.id)),
      verify: (bloc) {
        expect(bloc.state.visibleBlocks, [b1]);
        expect(
          bloc.state.notice,
          const CalendarNotice.failure(AppError.network()),
        );
      },
    );

    blocTest<CalendarBloc, CalendarState>(
      'si ya no existe en el servidor, se da por borrado',
      setUp: () => when(
        () => deleteBlock(any()),
      ).thenAnswer((_) async => const Failure(AppError.notFound())),
      build: build,
      seed: ready,
      act: (bloc) => bloc
        ..add(CalendarEvent.blockDeleteRequested(b1))
        ..add(CalendarEvent.blockDeleteCommitted(b1.id)),
      verify: (bloc) {
        expect(bloc.state.pendingDeletionIds, isEmpty);
        expect(bloc.state.notice, isNot(isA<CalendarNoticeFailure>()));
        // Como en un borrado correcto, recarga la semana.
        verify(() => getBlocks(any())).called(1);
      },
    );

    test('al cerrar la pantalla, lo pendiente se borra ya', () async {
      final bloc = build()..add(CalendarEvent.blockDeleteRequested(b1));
      await Future<void>.delayed(Duration.zero);
      await bloc.close();
      verify(() => deleteBlock(b1.id)).called(1);
    });
  });

  group('ficha del evento', () {
    final friday = DateTime(2025, 10, 17, 9);
    final moved = b1.copyWith(start: friday, end: friday.add(b1.duration));

    blocTest<CalendarBloc, CalendarState>(
      '«Pasar a otro día» mueve el evento y avisa de adónde fue',
      setUp: () => when(
        () => reschedule(
          'b1',
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => Success(BlockChange(block: moved))),
      build: build,
      seed: ready,
      act: (bloc) => bloc.add(
        CalendarEvent.blockMoved(
          blockId: 'b1',
          start: moved.start,
          end: moved.end,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.blocks.single, moved);
        expect(bloc.state.notice, CalendarNotice.moved(friday));
      },
    );

    blocTest<CalendarBloc, CalendarState>(
      'no pasa a otro día lo que ya está hecho',
      build: build,
      seed: () => ready().copyWith(blocks: [b1.copyWith(completed: true)]),
      act: (bloc) => bloc.add(
        CalendarEvent.blockMoved(
          blockId: 'b1',
          start: moved.start,
          end: moved.end,
        ),
      ),
      expect: () => [
        isA<CalendarState>().having(
          (s) => s.notice,
          'notice',
          const CalendarNotice.completedLocked(),
        ),
      ],
    );

    final routineDay = b1.copyWith(
      type: BlockType.sport,
      routineId: 'r1',
      routineDayId: 'd2',
    );

    blocTest<CalendarBloc, CalendarState>(
      '«Empezar el entreno» abre la sesión de ese día de rutina',
      setUp: () => when(
        () => startSession(routineId: 'r1', dayId: 'd2'),
      ).thenAnswer(
        (_) async => Success(
          TrainingSession(
            id: 's1',
            type: SessionType.routine,
            status: SessionStatus.inProgress,
            startedAt: testNow,
          ),
        ),
      ),
      build: build,
      seed: () => ready().copyWith(blocks: [routineDay]),
      act: (bloc) => bloc.add(const CalendarEvent.trainingStartRequested('b1')),
      expect: () => [
        isA<CalendarState>().having(
          (s) => s.startingTraining,
          'abriendo',
          isTrue,
        ),
        isA<CalendarState>()
            .having((s) => s.startingTraining, 'abriendo', isFalse)
            .having(
              (s) => s.notice,
              'notice',
              const CalendarNotice.sessionOpened('s1'),
            ),
      ],
    );

    blocTest<CalendarBloc, CalendarState>(
      'con una sesión a medias, avisa con el error del servidor',
      setUp: () => when(
        () => startSession(routineId: 'r1', dayId: 'd2'),
      ).thenAnswer(
        (_) async => const Failure(AppError.business('SESSION_STALE_OPEN')),
      ),
      build: build,
      seed: () => ready().copyWith(blocks: [routineDay]),
      act: (bloc) => bloc.add(const CalendarEvent.trainingStartRequested('b1')),
      verify: (bloc) => expect(
        bloc.state.notice,
        const CalendarNotice.failure(AppError.business('SESSION_STALE_OPEN')),
      ),
    );
  });
}
