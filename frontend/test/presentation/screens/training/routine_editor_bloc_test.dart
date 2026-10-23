import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/routine_draft.dart';
import 'package:synaptixfit/domain/use_cases/training/create_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/generate_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/refine_routine_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/routine_editor/bloc/routine_editor_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_effect.dart';

import 'training_fixtures.dart';

class _MockGenerate extends Mock implements GenerateRoutineUseCaseContract {}

class _MockRefine extends Mock implements RefineRoutineUseCaseContract {}

class _MockCreate extends Mock implements CreateRoutineUseCaseContract {}

void main() {
  late _MockGenerate generate;
  late _MockRefine refine;
  late _MockCreate create;

  const proposal = RoutineProposal(
    draft: RoutineDraft(
      name: 'Hipertrofia 4 semanas',
      goal: TrainingGoal.hypertrophy,
      weeks: [
        DraftWeek(
          name: 'Adaptación',
          days: [
            DraftDay(
              dayNumber: 1,
              exercises: [
                DraftExercise(
                  exerciseId: 'ex-squat',
                  exerciseName: 'Sentadilla',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    adjustmentReasons: ['Semana de exámenes: volumen reducido'],
    aiNotice: 'IA no disponible',
  );

  setUpAll(() {
    registerFallbackValue(const RoutineDraft());
    registerFallbackValue(const RoutineProposal(draft: RoutineDraft()));
  });

  setUp(() {
    generate = _MockGenerate();
    refine = _MockRefine();
    create = _MockCreate();
  });

  RoutineEditorBloc build() =>
      RoutineEditorBloc(generate: generate, refine: refine, create: create);

  RoutineEditorState editing(RoutineDraft draft) =>
      RoutineEditorState(aiMode: false, step: EditorStep.editing, draft: draft);

  const manualDraft = RoutineDraft(
    weeks: [
      DraftWeek(days: [DraftDay(dayNumber: 1)]),
    ],
  );

  blocTest<RoutineEditorBloc, RoutineEditorState>(
    'el modo manual abre el editor con una semana y un día vacíos',
    build: build,
    act: (bloc) => bloc.add(const RoutineEditorEvent.started(manual: true)),
    expect: () => [editing(manualDraft)],
  );

  blocTest<RoutineEditorBloc, RoutineEditorState>(
    'generar pasa por «generando» y abre la propuesta en el editor',
    setUp: () => when(
      () => generate(
        durationWeeks: any(named: 'durationWeeks'),
        goal: any(named: 'goal'),
        useAi: any(named: 'useAi'),
      ),
    ).thenAnswer((_) async => const Success(proposal)),
    build: build,
    act: (bloc) => bloc
      ..add(const RoutineEditorEvent.weeksParamChanged(6))
      ..add(const RoutineEditorEvent.generateRequested()),
    expect: () => [
      const RoutineEditorState(weeksParam: 6),
      const RoutineEditorState(weeksParam: 6, step: EditorStep.generating),
      RoutineEditorState(
        weeksParam: 6,
        step: EditorStep.editing,
        proposal: proposal,
        draft: proposal.draft,
      ),
    ],
    verify: (_) => verify(() => generate(durationWeeks: 6)).called(1),
  );

  blocTest<RoutineEditorBloc, RoutineEditorState>(
    'si generar falla vuelve a parámetros y emite el error',
    setUp: () =>
        when(
          () => generate(
            durationWeeks: any(named: 'durationWeeks'),
            goal: any(named: 'goal'),
            useAi: any(named: 'useAi'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure(AppError.business('TRAINING_PROFILE_REQUIRED')),
        ),
    build: build,
    act: (bloc) => bloc.add(const RoutineEditorEvent.generateRequested()),
    expect: () => const [
      RoutineEditorState(step: EditorStep.generating),
      RoutineEditorState(),
      RoutineEditorState(
        effect: TrainingEffect.error(
          AppError.business('TRAINING_PROFILE_REQUIRED'),
        ),
      ),
      RoutineEditorState(),
    ],
  );

  blocTest<RoutineEditorBloc, RoutineEditorState>(
    'añadir, subir y quitar ejercicios edita el día correcto',
    build: build,
    seed: () => editing(manualDraft),
    act: (bloc) => bloc
      ..add(
        const RoutineEditorEvent.exerciseAdded(0, 0, TrainingFixtures.squat),
      )
      ..add(const RoutineEditorEvent.exerciseAdded(0, 0, TrainingFixtures.run))
      ..add(const RoutineEditorEvent.exerciseMoved(0, 0, 1, up: true))
      ..add(const RoutineEditorEvent.exerciseRemoved(0, 0, 1)),
    verify: (bloc) {
      final exercises = bloc.state.draft.weeks.first.days.first.exercises;
      expect(exercises.map((e) => e.exerciseId), ['ex-run']);
      // Ejercicio aeróbico: se planifica por tiempo.
      expect(exercises.single.parameters.targetDurationSeconds, 600);
      expect(exercises.single.met, 8);
    },
  );

  blocTest<RoutineEditorBloc, RoutineEditorState>(
    'cambiar un ejercicio conserva sus series, repeticiones y descanso',
    build: build,
    seed: () => editing(manualDraft),
    act: (bloc) => bloc
      ..add(
        const RoutineEditorEvent.exerciseAdded(0, 0, TrainingFixtures.squat),
      )
      ..add(
        const RoutineEditorEvent.exerciseParametersChanged(
          0,
          0,
          0,
          ExerciseParameters(sets: 5, reps: 5, restSeconds: 180),
        ),
      )
      ..add(
        const RoutineEditorEvent.exerciseReplaced(
          0,
          0,
          0,
          TrainingFixtures.run,
        ),
      ),
    verify: (bloc) {
      final e = bloc.state.draft.weeks.first.days.first.exercises.single;
      expect(e.exerciseId, 'ex-run');
      expect(e.parameters.sets, 5);
      expect(e.parameters.restSeconds, 180);
      // Carrera se mide por tiempo: las repeticiones de la sentadilla no encajan.
      expect(e.parameters.targetDurationSeconds, 600);
    },
  );

  blocTest<RoutineEditorBloc, RoutineEditorState>(
    'cambiar por otro que se mide igual conserva repeticiones y peso',
    build: build,
    seed: () => editing(manualDraft),
    act: (bloc) => bloc
      ..add(
        const RoutineEditorEvent.exerciseAdded(0, 0, TrainingFixtures.squat),
      )
      ..add(
        const RoutineEditorEvent.exerciseParametersChanged(
          0,
          0,
          0,
          ExerciseParameters(sets: 4, reps: 6, restSeconds: 120, weightKg: 60),
        ),
      )
      ..add(
        RoutineEditorEvent.exerciseReplaced(
          0,
          0,
          0,
          TrainingFixtures.squat.copyWith(id: 'ex-press', name: 'Prensa'),
        ),
      ),
    verify: (bloc) {
      final e = bloc.state.draft.weeks.first.days.first.exercises.single;
      expect(e.exerciseName, 'Prensa');
      expect(
        e.parameters,
        const ExerciseParameters(
          sets: 4,
          reps: 6,
          restSeconds: 120,
          weightKg: 60,
        ),
      );
    },
  );

  blocTest<RoutineEditorBloc, RoutineEditorState>(
    'renombrar semana y día, y añadir un día ordenado por número',
    build: build,
    seed: () => editing(manualDraft),
    act: (bloc) => bloc
      ..add(const RoutineEditorEvent.weekRenamed(0, 'Base'))
      ..add(const RoutineEditorEvent.dayAdded(0, 5))
      ..add(const RoutineEditorEvent.dayAdded(0, 3))
      ..add(const RoutineEditorEvent.dayRenamed(0, 1, 'Pierna'))
      ..add(const RoutineEditorEvent.weekAdded()),
    verify: (bloc) {
      final weeks = bloc.state.draft.weeks;
      expect(weeks.first.name, 'Base');
      expect(weeks.first.days.map((d) => d.dayNumber), [1, 3, 5]);
      expect(weeks.first.days[1].name, 'Pierna');
      expect(weeks, hasLength(2));
      expect(weeks[1].name, isNull);
      expect(weeks[1].days.map((d) => d.dayNumber), [1, 3, 5]);
    },
  );

  blocTest<RoutineEditorBloc, RoutineEditorState>(
    'guardar sin nombre válido marca la validación y no llama a la API',
    build: build,
    seed: () => editing(manualDraft),
    act: (bloc) => bloc.add(const RoutineEditorEvent.saveRequested()),
    expect: () => [editing(manualDraft).copyWith(showValidation: true)],
    verify: (_) => verifyNever(() => create(any())),
  );

  blocTest<RoutineEditorBloc, RoutineEditorState>(
    'guardar crea la rutina y abre su detalle',
    setUp: () => when(
      () => create(any()),
    ).thenAnswer((_) async => Success(TrainingFixtures.routine())),
    build: build,
    seed: () => editing(manualDraft.copyWith(name: 'Mi rutina')),
    act: (bloc) => bloc.add(const RoutineEditorEvent.saveRequested()),
    expect: () {
      final base = editing(manualDraft.copyWith(name: 'Mi rutina'));
      return [
        base.copyWith(saving: true),
        base,
        base.copyWith(
          effect: const TrainingEffect.message(TrainingMessage.routineSaved),
        ),
        base,
        base.copyWith(
          effect: const TrainingEffect.openRoutine('r1', replace: true),
        ),
        base,
      ];
    },
  );

  blocTest<RoutineEditorBloc, RoutineEditorState>(
    'refinar conserva miniaturas, MET y visibilidad que la IA no devuelve',
    setUp: () => when(() => refine(any())).thenAnswer(
      (_) async => Success(
        proposal.copyWith(
          aiRefined: true,
          aiNotice: null,
          draft: proposal.draft.copyWith(name: 'Refinada'),
        ),
      ),
    ),
    build: build,
    seed: () => RoutineEditorState(
      step: EditorStep.editing,
      proposal: proposal,
      draft: proposal.draft.copyWith(
        weeks: [
          proposal.draft.weeks.first.copyWith(
            days: [
              const DraftDay(
                dayNumber: 1,
                exercises: [
                  DraftExercise(
                    exerciseId: 'ex-squat',
                    exerciseName: 'Sentadilla',
                    thumbnailUrl: 'https://cdn/squat.png',
                    met: 5,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
    act: (bloc) => bloc.add(const RoutineEditorEvent.refineRequested()),
    verify: (bloc) {
      final state = bloc.state;
      expect(state.refining, isFalse);
      expect(state.proposal?.aiRefined, isTrue);
      expect(state.draft.name, 'Refinada');
      final e = state.draft.weeks.first.days.first.exercises.single;
      expect(e.thumbnailUrl, 'https://cdn/squat.png');
      expect(e.met, 5);
    },
  );
}
