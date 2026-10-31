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
import 'package:synaptixfit/domain/use_cases/planner/reschedule_block_to_next_free_slot_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_timeline_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_week_balance_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_week_blocks_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_week_conflicts_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/reschedule_block_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/save_week_plan_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/set_block_completion_use_case.dart';
import 'package:synaptixfit/presentation/screens/planner/calendar/bloc/calendar_bloc.dart';

import 'planner_fixtures.dart';

class _Blocks extends Mock implements GetWeekBlocksUseCaseContract {}

class _Conflicts extends Mock implements GetWeekConflictsUseCaseContract {}

class _Timeline extends Mock implements GetTimelineUseCaseContract {}

class _Balance extends Mock implements GetWeekBalanceUseCaseContract {}

class _Reschedule extends Mock implements RescheduleBlockUseCaseContract {}

class _Completion extends Mock implements SetBlockCompletionUseCaseContract {}

class _SavePlan extends Mock implements SaveWeekPlanUseCaseContract {}

class _Account extends Mock implements GetAccountUseCaseContract {}

class _DeleteBlock extends Mock implements DeleteBlockUseCaseContract {}

class _RescheduleNext extends Mock
    implements RescheduleBlockToNextFreeSlotUseCaseContract {}

void main() {
  setUpAll(registerPlannerFallbacks);

  late _Blocks getBlocks;
  late _Conflicts getConflicts;
  late _Timeline getTimeline;
  late _Balance getBalance;
  late _Reschedule reschedule;
  late _Completion setCompletion;
  late _SavePlan savePlan;
  late _Account getAccount;
  late _DeleteBlock deleteBlock;
  late _RescheduleNext rescheduleNext;

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
    savePlan: savePlan,
    getAccount: getAccount,
    deleteBlock: deleteBlock,
    rescheduleNext: rescheduleNext,
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
    savePlan = _SavePlan();
    getAccount = _Account();
    deleteBlock = _DeleteBlock();
    rescheduleNext = _RescheduleNext();
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
          .having((s) => s.balance, 'balance', testBalance),
    ],
    verify: (_) => verify(() => getBlocks(testMonday)).called(1),
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
    'guardar el plan informa de la XP y no pide la cuenta si es 0',
    setUp: () => when(() => savePlan(testMonday)).thenAnswer(
      (_) async => const Success(
        SavedPlan(
          planId: 'p1',
          name: 'Plan',
          blockCount: 4,
          deadlineCount: 1,
          xpAwarded: 0,
        ),
      ),
    ),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(const CalendarEvent.planSaveRequested()),
    expect: () => [
      isA<CalendarState>().having((s) => s.savingPlan, 'saving', isTrue),
      isA<CalendarState>()
          .having((s) => s.savingPlan, 'saving', isFalse)
          .having(
            (s) => s.notice,
            'notice',
            const CalendarNotice.planSaved(xpAwarded: 0, blockCount: 4),
          ),
    ],
    verify: (_) => verifyNever(() => getAccount()),
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

  blocTest<CalendarBloc, CalendarState>(
    'reprogramar un bloque no hecho avisa de su nuevo horario y recarga',
    setUp: () => when(() => rescheduleNext(b1.id)).thenAnswer(
      (_) async => Success(BlockChange(block: b1.copyWith(start: testNow))),
    ),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(CalendarEvent.rescheduleNextRequested(b1.id)),
    verify: (bloc) {
      verify(() => rescheduleNext(b1.id)).called(1);
      verify(() => getBlocks(any())).called(1);
      expect(bloc.state.busyBlockIds, isEmpty);
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'sin hueco libre se avisa del error',
    setUp: () => when(() => rescheduleNext(b1.id)).thenAnswer(
      (_) async => const Failure(AppError.business('BLOCK_NO_FREE_SLOT')),
    ),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(CalendarEvent.rescheduleNextRequested(b1.id)),
    verify: (bloc) => expect(
      bloc.state.notice,
      const CalendarNotice.failure(AppError.business('BLOCK_NO_FREE_SLOT')),
    ),
  );
}
