import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/block_draft.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/domain/models/planner/deadline.dart';
import 'package:synaptixfit/domain/models/planner/planner_options.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/planner/create_block_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/distribute_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_deadlines_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_planner_challenges_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_planner_routines_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_planner_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/reschedule_block_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/update_block_use_case.dart';
import 'package:synaptixfit/presentation/screens/planner/block_editor/bloc/block_editor_bloc.dart';

import 'planner_fixtures.dart';

class _Subjects extends Mock implements GetPlannerSubjectsUseCaseContract {}

class _Routines extends Mock implements GetPlannerRoutinesUseCaseContract {}

class _Challenges extends Mock implements GetPlannerChallengesUseCaseContract {}

class _Deadlines extends Mock implements GetDeadlinesUseCaseContract {}

class _Create extends Mock implements CreateBlockUseCaseContract {}

class _Update extends Mock implements UpdateBlockUseCaseContract {}

class _Reschedule extends Mock implements RescheduleBlockUseCaseContract {}

class _Distribute extends Mock implements DistributeRoutineUseCaseContract {}

void main() {
  setUpAll(registerPlannerFallbacks);

  late _Subjects getSubjects;
  late _Routines getRoutines;
  late _Challenges getChallenges;
  late _Deadlines getDeadlines;
  late _Create create;
  late _Update update;
  late _Reschedule reschedule;
  late _Distribute distribute;

  const subject = SubjectOption(id: 's1', name: 'Cálculo');
  const routine = RoutineOption(id: 'r1', name: 'Fuerza');
  final existing = block();

  BlockEditorBloc build({CalendarBlock? editing}) => BlockEditorBloc(
    getSubjects: getSubjects,
    getRoutines: getRoutines,
    getChallenges: getChallenges,
    getDeadlines: getDeadlines,
    createBlock: create,
    updateBlock: update,
    reschedule: reschedule,
    distribute: distribute,
    block: editing,
    now: () => testNow,
  );

  BlockDraft draft({DateTime? start, int minutes = 60}) {
    final s = start ?? DateTime(2025, 10, 16, 9);
    return BlockDraft(
      type: BlockType.study,
      start: s,
      end: s.add(Duration(minutes: minutes)),
      subjectId: 's1',
    );
  }

  setUp(() {
    getSubjects = _Subjects();
    getRoutines = _Routines();
    getChallenges = _Challenges();
    getDeadlines = _Deadlines();
    create = _Create();
    update = _Update();
    reschedule = _Reschedule();
    distribute = _Distribute();
    when(() => getSubjects()).thenAnswer((_) async => const Success([subject]));
    when(() => getRoutines()).thenAnswer((_) async => const Success([routine]));
    when(
      () => getChallenges(),
    ).thenAnswer((_) async => const Failure(AppError.server()));
    when(() => getDeadlines(upcoming: true)).thenAnswer(
      (_) async =>
          Success(DeadlinePage(items: [deadline()], page: 0, totalPages: 1)),
    );
  });

  blocTest<BlockEditorBloc, BlockEditorState>(
    'carga los catálogos y conserva el formulario aunque falle alguno',
    build: build,
    act: (bloc) => bloc.add(const BlockEditorEvent.started()),
    expect: () => [
      isA<BlockEditorState>()
          .having((s) => s.status, 'status', BlockEditorStatus.ready)
          .having((s) => s.subjects, 'subjects', [subject])
          .having((s) => s.routines, 'routines', [routine])
          .having((s) => s.challenges, 'challenges', isEmpty)
          .having((s) => s.deadlines.single.id, 'deadline', 'd1')
          .having((s) => s.optionsError, 'error', const AppError.server()),
    ],
  );

  blocTest<BlockEditorBloc, BlockEditorState>(
    'crea el bloque y devuelve los solapes',
    setUp: () => when(() => create(any())).thenAnswer(
      (_) async => Success(
        BlockChange(
          block: existing,
          conflicts: [block(id: 'b2')],
        ),
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(BlockEditorEvent.saveRequested(draft())),
    expect: () => [
      isA<BlockEditorState>().having((s) => s.submitting, 'submitting', true),
      isA<BlockEditorState>().having(
        (s) => s.outcome,
        'outcome',
        const BlockEditorOutcome.created(overlaps: 1),
      ),
    ],
  );

  blocTest<BlockEditorBloc, BlockEditorState>(
    'al repetir cada semana envía las semanas y avisa de las copias',
    setUp: () => when(() => create(any())).thenAnswer(
      (_) async => Success(BlockChange(block: existing, weeklyCopies: 3)),
    ),
    build: build,
    act: (bloc) => bloc.add(
      BlockEditorEvent.saveRequested(draft().copyWith(repeatWeeks: 3)),
    ),
    expect: () => [
      isA<BlockEditorState>().having((s) => s.submitting, 'submitting', true),
      isA<BlockEditorState>().having(
        (s) => s.outcome,
        'outcome',
        const BlockEditorOutcome.created(overlaps: 0, weeklyCopies: 3),
      ),
    ],
    verify: (_) => verify(
      () => create(
        any(that: isA<BlockDraft>().having((d) => d.repeatWeeks, 'weeks', 3)),
      ),
    ).called(1),
  );

  blocTest<BlockEditorBloc, BlockEditorState>(
    'valida duración mínima y horas pasadas sin llamar a la API',
    build: build,
    act: (bloc) => bloc
      ..add(BlockEditorEvent.saveRequested(draft(minutes: 15)))
      ..add(
        BlockEditorEvent.saveRequested(draft(start: DateTime(2025, 10, 15, 8))),
      ),
    expect: () => [
      isA<BlockEditorState>().having(
        (s) => s.issue,
        'issue',
        BlockEditorIssue.tooShort,
      ),
      isA<BlockEditorState>().having(
        (s) => s.issue,
        'issue',
        BlockEditorIssue.inPast,
      ),
    ],
    verify: (_) => verifyNever(() => create(any())),
  );

  blocTest<BlockEditorBloc, BlockEditorState>(
    'al editar guarda los datos y reprograma si cambia el horario',
    setUp: () {
      when(
        () => update('b1', any()),
      ).thenAnswer((_) async => Success(existing));
      when(
        () => reschedule(
          'b1',
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => Success(BlockChange(block: existing)));
    },
    build: () => build(editing: existing),
    act: (bloc) => bloc.add(
      BlockEditorEvent.saveRequested(draft(start: DateTime(2025, 10, 17, 12))),
    ),
    skip: 1,
    expect: () => [
      isA<BlockEditorState>().having(
        (s) => s.outcome,
        'outcome',
        const BlockEditorOutcome.updated(),
      ),
    ],
    verify: (_) => verify(
      () => reschedule(
        'b1',
        start: DateTime(2025, 10, 17, 12),
        end: DateTime(2025, 10, 17, 13),
      ),
    ).called(1),
  );

  blocTest<BlockEditorBloc, BlockEditorState>(
    'al editar sin cambiar el horario no reprograma',
    setUp: () => when(
      () => update('b1', any()),
    ).thenAnswer((_) async => Success(existing)),
    build: () => build(editing: existing),
    act: (bloc) => bloc.add(BlockEditorEvent.saveRequested(draft())),
    verify: (_) => verifyNever(
      () => reschedule(
        any(),
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ),
  );

  blocTest<BlockEditorBloc, BlockEditorState>(
    'distribuye una rutina y exige al menos un día',
    setUp: () => when(
      () => distribute(any()),
    ).thenAnswer((_) async => Success([block(), block(id: 'b2')])),
    build: build,
    act: (bloc) => bloc
      ..add(
        BlockEditorEvent.distributionRequested(
          RoutineDistribution(
            routineId: 'r1',
            weekdays: const {},
            startDate: testMonday,
            preferredStartMinutes: 18 * 60,
            durationMinutes: 60,
          ),
        ),
      )
      ..add(
        BlockEditorEvent.distributionRequested(
          RoutineDistribution(
            routineId: 'r1',
            weekdays: const {1, 3},
            startDate: testMonday,
            preferredStartMinutes: 18 * 60,
            durationMinutes: 60,
          ),
        ),
      ),
    expect: () => [
      isA<BlockEditorState>().having(
        (s) => s.issue,
        'issue',
        BlockEditorIssue.noWeekdays,
      ),
      isA<BlockEditorState>().having((s) => s.submitting, 'submitting', true),
      isA<BlockEditorState>().having(
        (s) => s.outcome,
        'outcome',
        const BlockEditorOutcome.distributed(2),
      ),
    ],
  );
}
