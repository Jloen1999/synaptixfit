import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/challenge_link_type.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_references.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/exercise_progress.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/routine_template.dart';
import 'package:synaptixfit/domain/models/training/training_page.dart';
import 'package:synaptixfit/domain/models/training/wellbeing.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_weekly_plan_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_exercise_progress_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_pending_day_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_weekly_plan_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_weekly_plans_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_routine_templates_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/save_weekly_plan_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/use_routine_template_use_case.dart';
import 'package:synaptixfit/data/remote_data_source/training/dto/routine_dto.dart';
import 'package:synaptixfit/presentation/screens/training/exercise_progress/bloc/exercise_progress_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/routine_templates/bloc/routine_templates_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/weekly_plan/bloc/weekly_plan_bloc.dart';

const _home2 = RoutineTemplate(
  id: 't1',
  code: 'casa_2',
  name: 'En casa · 2 días',
  atHome: true,
  minutes: 35,
  weeks: 4,
  daysPerWeek: 2,
  dayNumbers: [2, 5],
);
const _gym3 = RoutineTemplate(
  id: 't2',
  code: 'cuerpo_completo_3',
  name: 'Cuerpo completo · 3 días',
  minutes: 50,
  weeks: 4,
  daysPerWeek: 3,
);
const _exam = RoutineTemplate(
  id: 't3',
  code: 'examenes_casa',
  name: 'Semana de exámenes · en casa',
  atHome: true,
  forExams: true,
  minutes: 20,
  weeks: 2,
  daysPerWeek: 3,
);

const _routine = Routine(
  id: 'r1',
  ownerId: 'u1',
  owned: true,
  name: 'En casa · 2 días',
  visibility: Visibility.private,
  status: RoutineStatus.active,
  durationWeeks: 4,
  exerciseCount: 10,
  totalDays: 8,
  completedDays: 0,
);

class _List implements ListRoutineTemplatesUseCaseContract {
  @override
  Future<AppResult<List<RoutineTemplate>>> call() async =>
      const Success([_home2, _gym3, _exam]);
}

class _Use implements UseRoutineTemplateUseCaseContract {
  _Use({this.fail = false});

  final bool fail;
  final used = <String>[];

  @override
  Future<AppResult<Routine>> call(String templateId) async {
    used.add(templateId);
    return fail ? const Failure(AppError.network()) : const Success(_routine);
  }
}

class _Progress implements GetExerciseProgressUseCaseContract {
  @override
  Future<AppResult<List<ExerciseProgressPoint>>> call(String id) async =>
      Success([
        ExerciseProgressPoint(
          date: DateTime(2026, 10, 1),
          estimatedMaxKg: 75,
          weightKg: 60,
          reps: 8,
        ),
        ExerciseProgressPoint(
          date: DateTime(2026, 10, 15),
          estimatedMaxKg: 82.5,
          weightKg: 72.5,
          reps: 6,
        ),
      ]);
}

class _GetPlan implements GetWeeklyPlanUseCaseContract {
  @override
  Future<AppResult<WeeklyPlan?>> call(DateTime weekStart) async =>
      const Success(null);
}

class _GetPlans implements GetWeeklyPlansUseCaseContract {
  @override
  Future<AppResult<TrainingPage<WeeklyPlan>>> call({
    int page = 0,
    int size = 20,
  }) async => const Success(
    TrainingPage(items: [], page: 0, totalPages: 0, totalItems: 0),
  );
}

class _SavePlan implements SaveWeeklyPlanUseCaseContract {
  @override
  Future<AppResult<WeeklyPlan>> call(DateTime w, WeeklyPlanInput i) async =>
      const Failure(AppError.network());
}

class _DeletePlan implements DeleteWeeklyPlanUseCaseContract {
  @override
  Future<AppResult<Unit>> call(DateTime weekStart) async =>
      const Failure(AppError.network());
}

class _Pending implements GetPendingDayUseCaseContract {
  _Pending(this.day);

  final PendingDay? day;

  @override
  Future<AppResult<PendingDay?>> call() async => Success(day);
}

void main() {
  group('Plantillas listas', () {
    blocTest<RoutineTemplatesBloc, RoutineTemplatesState>(
      'filtra por casa y exámenes sin volver a pedirlas',
      build: () => RoutineTemplatesBloc(list: _List(), use: _Use()),
      act: (bloc) => bloc
        ..add(const RoutineTemplatesEvent.started())
        ..add(
          const RoutineTemplatesEvent.filterChanged(
            TemplateFilter(atHome: true, forExams: true),
          ),
        ),
      verify: (bloc) {
        expect(bloc.state.status, TemplatesStatus.ready);
        expect(bloc.state.dayOptions, [2, 3]);
        expect(bloc.state.visible, [_exam]);
      },
    );

    test('filtrar por días deja solo las de esos días', () {
      const filter = TemplateFilter(days: 3);
      expect([_home2, _gym3, _exam].where(filter.matches), [_gym3, _exam]);
    });

    late _Use use;
    blocTest<RoutineTemplatesBloc, RoutineTemplatesState>(
      'un toque crea la rutina y la entrega una sola vez para abrirla',
      build: () {
        use = _Use();
        return RoutineTemplatesBloc(list: _List(), use: use);
      },
      act: (bloc) => bloc.add(const RoutineTemplatesEvent.used('t1')),
      expect: () => [
        isA<RoutineTemplatesState>().having((s) => s.usingId, 'ocupado', 't1'),
        isA<RoutineTemplatesState>().having((s) => s.created, 'creada', _routine),
        isA<RoutineTemplatesState>().having((s) => s.created, 'consumida', null),
      ],
      verify: (_) => expect(use.used, ['t1']),
    );

    blocTest<RoutineTemplatesBloc, RoutineTemplatesState>(
      'sin conexión avisa del error y deja volver a intentarlo',
      build: () => RoutineTemplatesBloc(list: _List(), use: _Use(fail: true)),
      act: (bloc) => bloc.add(const RoutineTemplatesEvent.used('t2')),
      verify: (bloc) {
        expect(bloc.state.usingId, isNull);
        expect(bloc.state.created, isNull);
      },
    );
  });

  blocTest<ExerciseProgressBloc, ExerciseProgressState>(
    'la evolución muestra la mejor marca y cuánto ha subido',
    build: () => ExerciseProgressBloc(get: _Progress()),
    act: (bloc) => bloc.add(const ExerciseProgressRequested('e1')),
    verify: (bloc) {
      expect(bloc.state.status, ExerciseProgressStatus.ready);
      expect(bloc.state.best?.estimatedMaxKg, 82.5);
      expect(bloc.state.change, closeTo(7.5, 0.001));
    },
  );

  group('Plan semanal según la rutina', () {
    PendingDay day(int sessions) => PendingDay(
      routineId: 'r1',
      routineName: 'Fuerza',
      weekId: 'w1',
      weekNumber: 1,
      dayId: 'd1',
      dayNumber: 1,
      dayStatus: ProgressStatus.pending,
      sessionsInWeek: sessions,
    );

    WeeklyPlanBloc build(PendingDay? pending) => WeeklyPlanBloc(
      getPlan: _GetPlan(),
      getPlans: _GetPlans(),
      savePlan: _SavePlan(),
      deletePlan: _DeletePlan(),
      getPendingDay: _Pending(pending),
      clock: () => DateTime(2026, 11, 4),
    );

    blocTest<WeeklyPlanBloc, WeeklyPlanState>(
      'sin plan guardado propone los días de la rutina («Según tu rutina: 4»)',
      build: () => build(day(4)),
      act: (bloc) => bloc.add(const WeeklyPlanEvent.started()),
      verify: (bloc) {
        expect(bloc.state.routineSessions, 4);
        expect(bloc.state.routineName, 'Fuerza');
        expect(bloc.state.input.plannedSessions, 4);
      },
    );

    blocTest<WeeklyPlanBloc, WeeklyPlanState>(
      'sin rutina en curso no sugiere nada y deja el valor de siempre',
      build: () => build(null),
      act: (bloc) => bloc.add(const WeeklyPlanEvent.started()),
      verify: (bloc) {
        expect(bloc.state.routineSessions, isNull);
        expect(bloc.state.input.plannedSessions, 3);
      },
    );
  });

  test('la rutina trae el plan por fases y las fechas de cada semana', () {
    final routine = RoutineDto.fromJson({
      'id': 'r1',
      'ownerId': 'u1',
      'name': 'Fuerza',
      'currentWeek': 2,
      'progressPercent': 25,
      'nextStep': 'NEW_PLAN',
      'weeks': [
        {
          'id': 'w1',
          'number': 1,
          'type': 'DELOAD',
          'status': 'PENDING',
          'startsOn': '2026-11-02',
          'endsOn': '2026-11-08',
        },
      ],
    }).toDomain();

    expect(routine.currentWeek, 2);
    expect(routine.progressPercent, 25);
    expect(routine.nextStep, RoutineNextStep.newPlan);
    expect(routine.weeks.single.startsOn, DateTime(2026, 11, 2));
    expect(routine.weeks.single.type, WeekType.deload);
  });

  test('un día de rutina se puede vincular aunque no tenga fecha', () {
    const option = ChallengeLinkOption(
      id: 'd1',
      type: ChallengeLinkType.routineDay,
      title: 'Fuerza',
      weekNumber: 2,
      dayNumber: 3,
    );
    expect(option.at, isNull);
    expect(option.weekNumber, 2);
  });
}
