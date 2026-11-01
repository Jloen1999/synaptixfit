import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/use_cases/training/add_routine_day_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/add_routine_exercise_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/add_routine_week_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/change_routine_status_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/clone_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_routine_day_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_routine_week_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/duplicate_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_body_weight_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_my_routines_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/remove_routine_exercise_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/rename_routine_day_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/reorder_routine_exercises_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/replace_routine_exercise_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/restart_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/skip_routine_day_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/start_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/unskip_routine_day_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/update_routine_exercise_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/update_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/update_routine_week_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/routine_detail/bloc/routine_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_effect.dart';

import 'training_fixtures.dart';

class _GetRoutine extends Mock implements GetRoutineUseCaseContract {}

class _GetWeight extends Mock implements GetBodyWeightUseCaseContract {}

class _Update extends Mock implements UpdateRoutineUseCaseContract {}

class _Status extends Mock implements ChangeRoutineStatusUseCaseContract {}

class _Delete extends Mock implements DeleteRoutineUseCaseContract {}

class _Duplicate extends Mock implements DuplicateRoutineUseCaseContract {}

class _Clone extends Mock implements CloneRoutineUseCaseContract {}

class _AddWeek extends Mock implements AddRoutineWeekUseCaseContract {}

class _UpdateWeek extends Mock implements UpdateRoutineWeekUseCaseContract {}

class _DeleteWeek extends Mock implements DeleteRoutineWeekUseCaseContract {}

class _AddDay extends Mock implements AddRoutineDayUseCaseContract {}

class _RenameDay extends Mock implements RenameRoutineDayUseCaseContract {}

class _DeleteDay extends Mock implements DeleteRoutineDayUseCaseContract {}

class _AddExercise extends Mock implements AddRoutineExerciseUseCaseContract {}

class _Reorder extends Mock implements ReorderRoutineExercisesUseCaseContract {}

class _UpdateExercise extends Mock
    implements UpdateRoutineExerciseUseCaseContract {}

class _RemoveExercise extends Mock
    implements RemoveRoutineExerciseUseCaseContract {}

class _Start extends Mock implements StartSessionUseCaseContract {}

class _MyRoutines extends Mock implements GetMyRoutinesUseCaseContract {}

class _Skip extends Mock implements SkipRoutineDayUseCaseContract {}

class _Unskip extends Mock implements UnskipRoutineDayUseCaseContract {}

class _Restart extends Mock implements RestartRoutineUseCaseContract {}

class _Replace extends Mock implements ReplaceRoutineExerciseUseCaseContract {}

void main() {
  late _GetRoutine getRoutine;
  late _GetWeight getWeight;
  late _Delete deleteRoutine;
  late _Clone clone;
  late _Reorder reorder;
  late _RenameDay renameDay;
  late _RemoveExercise removeExercise;
  late RoutineDetailUseCases useCases;
  late _MyRoutines myRoutines;
  late _Skip skip;
  late _UpdateExercise updateExercise;
  late _Replace replace;
  final routine = TrainingFixtures.routine();

  setUpAll(() => registerFallbackValue(RoutineStatus.active));

  setUp(() {
    getRoutine = _GetRoutine();
    getWeight = _GetWeight();
    deleteRoutine = _Delete();
    clone = _Clone();
    reorder = _Reorder();
    renameDay = _RenameDay();
    removeExercise = _RemoveExercise();
    myRoutines = _MyRoutines();
    skip = _Skip();
    updateExercise = _UpdateExercise();
    replace = _Replace();
    // Sin otra rutina en curso (el aviso de «se pausará» no aplica).
    when(
      () => myRoutines(
        status: any(named: 'status'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => const Failure(AppError.network()));
    useCases = RoutineDetailUseCases(
      getRoutine: getRoutine,
      getBodyWeight: getWeight,
      updateRoutine: _Update(),
      changeStatus: _Status(),
      deleteRoutine: deleteRoutine,
      duplicateRoutine: _Duplicate(),
      cloneRoutine: clone,
      addWeek: _AddWeek(),
      updateWeek: _UpdateWeek(),
      deleteWeek: _DeleteWeek(),
      addDay: _AddDay(),
      renameDay: renameDay,
      deleteDay: _DeleteDay(),
      addExercise: _AddExercise(),
      reorderExercises: reorder,
      updateExercise: updateExercise,
      removeExercise: removeExercise,
      startSession: _Start(),
      getMyRoutines: myRoutines,
      skipDay: skip,
      unskipDay: _Unskip(),
      restartRoutine: _Restart(),
      replaceExercise: replace,
    );
  });

  RoutineDetailState ready([Routine? r]) => RoutineDetailState(
    status: RoutineDetailStatus.ready,
    routineId: 'r1',
    routine: r ?? routine,
    bodyWeightKg: 80,
  );

  blocTest<RoutineDetailBloc, RoutineDetailState>(
    'carga la rutina y el peso del perfil',
    setUp: () {
      when(() => getRoutine('r1')).thenAnswer((_) async => Success(routine));
      when(() => getWeight()).thenAnswer((_) async => const Success(80.0));
    },
    build: () => RoutineDetailBloc(useCases),
    act: (bloc) => bloc.add(const RoutineDetailEvent.started('r1')),
    expect: () => [const RoutineDetailState(routineId: 'r1'), ready()],
  );

  blocTest<RoutineDetailBloc, RoutineDetailState>(
    'si la rutina no existe muestra el error (el peso es opcional)',
    setUp: () {
      when(() => getRoutine('r1')).thenAnswer(
        (_) async => const Failure(AppError.business('ROUTINE_NOT_FOUND')),
      );
      when(
        () => getWeight(),
      ).thenAnswer((_) async => const Failure(AppError.notFound()));
    },
    build: () => RoutineDetailBloc(useCases),
    act: (bloc) => bloc.add(const RoutineDetailEvent.started('r1')),
    expect: () => const [
      RoutineDetailState(routineId: 'r1'),
      RoutineDetailState(
        routineId: 'r1',
        status: RoutineDetailStatus.failure,
        error: AppError.business('ROUTINE_NOT_FOUND'),
      ),
    ],
  );

  blocTest<RoutineDetailBloc, RoutineDetailState>(
    'bajar un ejercicio envía el nuevo orden completo del día',
    setUp: () => when(
      () => reorder('r1', 'd1', ['p2', 'p1']),
    ).thenAnswer((_) async => Success(routine.copyWith(name: 'Reordenada'))),
    build: () => RoutineDetailBloc(useCases),
    seed: ready,
    act: (bloc) =>
        bloc.add(const RoutineDetailEvent.exerciseMoved('d1', 'p1', up: false)),
    // Sin estado de carga: primero el orden nuevo en pantalla, luego lo que
    // confirma el servidor.
    expect: () => [
      ready(routine.withExerciseOrder('d1', ['p2', 'p1'])),
      ready(routine.copyWith(name: 'Reordenada')),
    ],
  );

  blocTest<RoutineDetailBloc, RoutineDetailState>(
    'si el servidor no guarda el orden, se avisa y vuelve lo guardado',
    setUp: () {
      when(
        () => reorder('r1', 'd1', ['p2', 'p1']),
      ).thenAnswer((_) async => const Failure(AppError.network()));
      when(() => getRoutine('r1')).thenAnswer((_) async => Success(routine));
    },
    build: () => RoutineDetailBloc(useCases),
    seed: ready,
    act: (bloc) =>
        bloc.add(const RoutineDetailEvent.exerciseMoved('d1', 'p1', up: false)),
    expect: () {
      final moved = ready(routine.withExerciseOrder('d1', ['p2', 'p1']));
      return [
        moved,
        moved.copyWith(effect: const TrainingEffect.error(AppError.network())),
        moved,
        ready(),
      ];
    },
  );

  blocTest<RoutineDetailBloc, RoutineDetailState>(
    'dos movimientos seguidos se envían en orden y manda el último',
    setUp: () {
      when(() => reorder('r1', 'd1', ['p2', 'p1'])).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return Success(routine.copyWith(name: 'Primera'));
      });
      when(
        () => reorder('r1', 'd1', ['p1', 'p2']),
      ).thenAnswer((_) async => Success(routine.copyWith(name: 'Segunda')));
    },
    build: () => RoutineDetailBloc(useCases),
    seed: ready,
    act: (bloc) async {
      bloc.add(const RoutineDetailEvent.exerciseMoved('d1', 'p1', up: false));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RoutineDetailEvent.exerciseMoved('d1', 'p1', up: true));
    },
    wait: const Duration(milliseconds: 60),
    expect: () => [
      ready(routine.withExerciseOrder('d1', ['p2', 'p1'])),
      ready(routine.withExerciseOrder('d1', ['p1', 'p2'])),
      ready(routine.copyWith(name: 'Segunda')),
    ],
    verify: (_) => verifyInOrder([
      () => reorder('r1', 'd1', ['p2', 'p1']),
      () => reorder('r1', 'd1', ['p1', 'p2']),
    ]),
  );

  blocTest<RoutineDetailBloc, RoutineDetailState>(
    'quitar un ejercicio mientras se guarda el orden espera a ese guardado',
    setUp: () {
      when(() => reorder('r1', 'd1', ['p2', 'p1'])).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return Success(routine.copyWith(name: 'Reordenada'));
      });
      when(
        () => removeExercise('r1', 'p1'),
      ).thenAnswer((_) async => Success(routine.copyWith(name: 'Sin p1')));
    },
    build: () => RoutineDetailBloc(useCases),
    seed: ready,
    act: (bloc) async {
      bloc.add(const RoutineDetailEvent.exerciseMoved('d1', 'p1', up: false));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RoutineDetailEvent.exerciseRemoved('p1'));
    },
    wait: const Duration(milliseconds: 60),
    expect: () {
      final moved = ready(routine.withExerciseOrder('d1', ['p2', 'p1']));
      return [
        moved,
        moved.copyWith(busy: true),
        ready(routine.copyWith(name: 'Reordenada')).copyWith(busy: true),
        ready(routine.copyWith(name: 'Sin p1')),
        ready(routine.copyWith(name: 'Sin p1')).copyWith(
          effect: const TrainingEffect.message(TrainingMessage.exerciseRemoved),
        ),
        ready(routine.copyWith(name: 'Sin p1')),
      ];
    },
    verify: (_) => verifyInOrder([
      () => reorder('r1', 'd1', ['p2', 'p1']),
      () => removeExercise('r1', 'p1'),
    ]),
  );

  group('edición en línea', () {
    const four = ExerciseParameters(sets: 4, reps: 10, restSeconds: 90);
    const five = ExerciseParameters(sets: 5, reps: 10, restSeconds: 90);

    blocTest<RoutineDetailBloc, RoutineDetailState>(
      'se ve al instante, no bloquea y adopta la rutina del servidor',
      setUp: () => when(() => updateExercise('r1', 'p1', four)).thenAnswer(
        (_) async => Success(routine.withExerciseParameters('p1', four)),
      ),
      build: () => RoutineDetailBloc(useCases),
      seed: ready,
      act: (bloc) =>
          bloc.add(const RoutineDetailEvent.exerciseUpdated('p1', four)),
      expect: () => [
        ready(
          routine.withExerciseParameters('p1', four),
        ).copyWith(saving: true),
        ready(routine.withExerciseParameters('p1', four)),
      ],
    );

    blocTest<RoutineDetailBloc, RoutineDetailState>(
      'dos cambios seguidos se guardan en orden y manda el último',
      setUp: () {
        when(() => updateExercise('r1', 'p1', four)).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return Success(routine.withExerciseParameters('p1', four));
        });
        when(() => updateExercise('r1', 'p1', five)).thenAnswer(
          (_) async => Success(routine.withExerciseParameters('p1', five)),
        );
      },
      build: () => RoutineDetailBloc(useCases),
      seed: ready,
      act: (bloc) async {
        bloc.add(const RoutineDetailEvent.exerciseUpdated('p1', four));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RoutineDetailEvent.exerciseUpdated('p1', five));
      },
      wait: const Duration(milliseconds: 60),
      // La respuesta del primero no pisa el segundo, que sigue a la vista.
      expect: () => [
        ready(
          routine.withExerciseParameters('p1', four),
        ).copyWith(saving: true),
        ready(
          routine.withExerciseParameters('p1', five),
        ).copyWith(saving: true),
        ready(routine.withExerciseParameters('p1', five)),
      ],
      verify: (_) => verifyInOrder([
        () => updateExercise('r1', 'p1', four),
        () => updateExercise('r1', 'p1', five),
      ]),
    );

    blocTest<RoutineDetailBloc, RoutineDetailState>(
      'sustituir un ejercicio guarda y avisa',
      setUp: () => when(
        () => replace('r1', 'p1', 'e9'),
      ).thenAnswer((_) async => Success(routine.copyWith(name: 'Con e9'))),
      build: () => RoutineDetailBloc(useCases),
      seed: ready,
      act: (bloc) =>
          bloc.add(const RoutineDetailEvent.exerciseReplaced('p1', 'e9')),
      expect: () => [
        ready().copyWith(busy: true),
        ready(routine.copyWith(name: 'Con e9')),
        ready(routine.copyWith(name: 'Con e9')).copyWith(
          effect: const TrainingEffect.message(
            TrainingMessage.exerciseReplaced,
          ),
        ),
        ready(routine.copyWith(name: 'Con e9')),
      ],
    );
  });

  blocTest<RoutineDetailBloc, RoutineDetailState>(
    'un error al editar se avisa sin perder la rutina',
    setUp: () => when(() => renameDay('r1', 'd1', 'Pierna')).thenAnswer(
      (_) async => const Failure(AppError.business('ROUTINE_DAY_NOT_FOUND')),
    ),
    build: () => RoutineDetailBloc(useCases),
    seed: ready,
    act: (bloc) =>
        bloc.add(const RoutineDetailEvent.dayRenamed('d1', 'Pierna')),
    expect: () => [
      ready().copyWith(busy: true),
      ready(),
      ready().copyWith(
        effect: const TrainingEffect.error(
          AppError.business('ROUTINE_DAY_NOT_FOUND'),
        ),
      ),
      ready(),
    ],
  );

  blocTest<RoutineDetailBloc, RoutineDetailState>(
    'eliminar la rutina avisa y cierra la pantalla',
    setUp: () => when(
      () => deleteRoutine('r1'),
    ).thenAnswer((_) async => const Success(unit)),
    build: () => RoutineDetailBloc(useCases),
    seed: ready,
    act: (bloc) => bloc.add(const RoutineDetailEvent.deleted()),
    expect: () => [
      ready().copyWith(busy: true),
      ready(),
      ready().copyWith(
        effect: const TrainingEffect.message(TrainingMessage.routineDeleted),
      ),
      ready(),
      ready().copyWith(effect: const TrainingEffect.close()),
      ready(),
    ],
  );

  blocTest<RoutineDetailBloc, RoutineDetailState>(
    'clonar una rutina ajena abre la copia',
    setUp: () => when(
      () => clone('r1'),
    ).thenAnswer((_) async => Success(routine.copyWith(id: 'r2'))),
    build: () => RoutineDetailBloc(useCases),
    seed: () => ready(TrainingFixtures.routine(owned: false)),
    act: (bloc) => bloc.add(const RoutineDetailEvent.cloned()),
    verify: (_) => verify(() => clone('r1')).called(1),
    expect: () {
      final base = ready(TrainingFixtures.routine(owned: false));
      return [
        base.copyWith(busy: true),
        base,
        base.copyWith(
          effect: const TrainingEffect.message(TrainingMessage.routineCloned),
        ),
        base,
        base.copyWith(
          effect: const TrainingEffect.openRoutine('r2', replace: true),
        ),
        base,
      ];
    },
  );
}
