import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/training/dto/page_dto.dart';
import 'package:synaptixfit/data/remote_data_source/training/dto/proposal_dto.dart';
import 'package:synaptixfit/data/remote_data_source/training/dto/routine_dto.dart';
import 'package:synaptixfit/data/remote_data_source/training/dto/session_dto.dart';
import 'package:synaptixfit/data/remote_data_source/training/dto/wellbeing_dto.dart';
import 'package:synaptixfit/data/repository/routine_repository.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/routine_draft.dart';

Map<String, dynamic> _planned(String id, int order) => {
  'id': id,
  'exerciseId': 'ex-$id',
  'exerciseName': 'Ejercicio $id',
  'gifUrl': '',
  'previewUrl': 'https://cdn/$id.png',
  'modality': 'STRENGTH',
  'measurementTypes': ['REPETITIONS', 'WEIGHT'],
  'met': 5.0,
  'exerciseActive': true,
  'order': order,
  'sets': 4,
  'reps': 8,
  'restSeconds': 120,
  'weightKg': 40.0,
  'weightsKg': null,
  'targetDurationSeconds': null,
  'distanceMeters': null,
  'isometricSeconds': null,
  'realDurationSeconds': 300,
};

void main() {
  group('RoutineDto', () {
    final json = {
      'id': 'r1',
      'ownerId': 'u1',
      'authorName': 'Ana',
      'owned': false,
      'name': 'Fuerza',
      'description': null,
      'visibility': 'PUBLIC',
      'status': 'PAUSED',
      'goal': 'MAX_STRENGTH',
      'startDate': '2026-10-19',
      'durationWeeks': 2,
      'exerciseCount': 2,
      'totalDays': 2,
      'completedDays': 1,
      'origin': {'routineId': 'r0', 'ownerId': 'u0', 'ownerName': 'Luis'},
      'createdAt': '2026-10-01T08:00:00Z',
      'weeks': [
        {
          'id': 'w2',
          'number': 2,
          'name': null,
          'type': 'DELOAD',
          'status': 'PENDING',
          'days': [],
        },
        {
          'id': 'w1',
          'number': 1,
          'name': 'Base',
          'type': 'ADAPTATION',
          'status': 'COMPLETED',
          'days': [
            {
              'id': 'd3',
              'dayNumber': 3,
              'name': null,
              'status': 'PENDING',
              'exercises': [_planned('b', 1), _planned('a', 0)],
            },
            {
              'id': 'd1',
              'dayNumber': 1,
              'name': 'Pierna',
              'status': 'COMPLETED',
              'exercises': [],
            },
          ],
        },
      ],
    };

    test('mapea enums, fechas y ordena semanas, días y ejercicios', () {
      final routine = RoutineDto.fromJson(json).toDomain();
      expect(routine.owned, isFalse);
      expect(routine.visibility, Visibility.public);
      expect(routine.status, RoutineStatus.paused);
      expect(routine.goal, TrainingGoal.maxStrength);
      expect(routine.startDate, DateTime(2026, 10, 19));
      expect(routine.createdAt!.isUtc, isFalse);
      expect(routine.origin!.ownerName, 'Luis');
      expect(routine.weeks.map((w) => w.number), [1, 2]);
      expect(routine.weeks.first.type, WeekType.adaptation);
      expect(routine.weeks.first.status, ProgressStatus.completed);
      expect(routine.weeks.first.days.map((d) => d.dayNumber), [1, 3]);
      final exercises = routine.weeks.first.days[1].exercises;
      expect(exercises.map((e) => e.id), ['a', 'b']);
      final a = exercises.first;
      expect(a.gifUrl, isNull, reason: 'las URLs vacías se ignoran');
      expect(a.thumbnailUrl, 'https://cdn/a.png');
      expect(a.measurementTypes, [
        MeasurementType.repetitions,
        MeasurementType.weight,
      ]);
      expect(
        a.parameters,
        const ExerciseParameters(
          sets: 4,
          reps: 8,
          restSeconds: 120,
          weightKg: 40,
        ),
      );
      expect(a.realDurationSeconds, 300);
      expect(routine.dayById('d3')?.dayNumber, 3);
    });

    test('un objetivo desconocido o nulo queda como null', () {
      final routine = RoutineDto.fromJson({
        ...json,
        'goal': null,
        'weeks': [],
      }).toDomain();
      expect(routine.goal, isNull);
    });
  });

  group('Propuestas y alta', () {
    test('la propuesta de la API se convierte en borrador editable', () {
      final proposal = RoutineProposalDto.fromJson({
        'name': 'Plan',
        'description': 'Desc',
        'goal': 'HYPERTROPHY',
        'durationWeeks': 1,
        'split': 'FULL_BODY',
        'adjustmentReasons': ['Exámenes'],
        'totalLoadFactor': 0.8,
        'aiRefined': false,
        'aiNotice': 'IA no disponible',
        'weeks': [
          {
            'number': 1,
            'name': 'Semana 1',
            'type': 'LOAD',
            'days': [
              {
                'dayNumber': 4,
                'name': 'Jueves',
                'exercises': [
                  {
                    'exerciseId': 'ex1',
                    'exerciseName': 'Press',
                    'sets': 3,
                    'reps': 10,
                    'restSeconds': 90,
                  },
                ],
              },
              {'dayNumber': 2, 'name': null, 'exercises': []},
            ],
          },
        ],
      }).toDomain();
      expect(proposal.aiRefined, isFalse);
      expect(proposal.aiNotice, 'IA no disponible');
      expect(proposal.adjustmentReasons, ['Exámenes']);
      expect(proposal.draft.goal, TrainingGoal.hypertrophy);
      final week = proposal.draft.weeks.single;
      expect(week.type, WeekType.load);
      expect(week.days.map((d) => d.dayNumber), [2, 4]);
      expect(week.days[1].exercises.single.exerciseName, 'Press');
    });

    const draft = RoutineDraft(
      name: '  Mi rutina  ',
      description: '   ',
      visibility: Visibility.friends,
      weeks: [
        DraftWeek(
          name: 'Base',
          days: [
            DraftDay(
              dayNumber: 1,
              exercises: [
                DraftExercise(
                  exerciseId: 'ex1',
                  exerciseName: 'Press',
                  parameters: ExerciseParameters(weightKg: 20),
                ),
              ],
            ),
          ],
        ),
        DraftWeek(days: []),
      ],
    );

    test('el alta omite nulos y recorta textos', () {
      final json = CreateRoutineRequestDto.fromDomain(draft).toJson();
      expect(json['name'], 'Mi rutina');
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('goal'), isFalse);
      expect(json['visibility'], 'FRIENDS');
      final weeks = json['weeks'] as List;
      expect(weeks, hasLength(2));
      final first = weeks.first as Map<String, dynamic>;
      expect(first.containsKey('number'), isFalse);
      expect(first['name'], 'Base');
      final exercise =
          ((first['days'] as List).single as Map)['exercises'] as List;
      expect(exercise.single, {
        'exerciseId': 'ex1',
        'exerciseName': 'Press',
        'sets': 3,
        'reps': 10,
        'restSeconds': 90,
        'weightKg': 20.0,
      });
    });

    test('refinar numera las semanas y exige objetivo', () {
      final json = RoutineProposalDto.fromDomain(
        const RoutineProposal(draft: draft),
      ).toJson();
      expect(json['goal'], 'HYPERTROPHY');
      expect(json['durationWeeks'], 2);
      expect((json['weeks'] as List).map((w) => (w as Map)['number']), [1, 2]);
    });

    test('los parámetros se envían sin nulos', () {
      expect(
        parametersToJson(
          const ExerciseParameters(
            sets: 2,
            reps: 12,
            restSeconds: 60,
            isometricSeconds: 30,
          ),
        ),
        {'sets': 2, 'reps': 12, 'restSeconds': 60, 'isometricSeconds': 30},
      );
    });
  });

  group('Sesiones y bienestar', () {
    test('finalizar sesión mapea sesión, experiencia y sugerencias', () {
      final result = FinishSessionResponseDto.fromJson({
        'session': {
          'id': 's1',
          'routineId': 'r1',
          'dayId': 'd1',
          'type': 'ROUTINE',
          'status': 'COMPLETED',
          'startedAt': '2026-10-18T08:00:00Z',
          'completedAt': '2026-10-18T09:00:00Z',
          'durationMinutes': 60,
          'rpe': 7,
          'calories': 412.5,
          'xpAwarded': 50,
          'sets': [
            {
              'id': 'x1',
              'plannedExerciseId': 'p1',
              'setNumber': 1,
              'repsDone': 10,
              'weightKg': 40.0,
              'completed': true,
              'failedReps': 0,
            },
          ],
        },
        'experience': {'level': 4, 'levelXp': 10, 'levelUps': 1, 'xpDelta': 50},
        'recommendations': [
          {
            'id': 'rec1',
            'type': 'PROGRESSION',
            'title': 'Sube peso',
            'description': null,
            'exerciseId': 'ex1',
            'routineId': 'r1',
            'applied': false,
            'createdAt': '2026-10-18T09:00:00Z',
            'adjustments': [
              {
                'plannedExerciseId': 'p1',
                'exerciseId': 'ex1',
                'exerciseName': 'Press',
                'reason': '+2,5 kg',
                'sets': 4,
                'reps': 8,
                'restSeconds': 120,
                'weightKg': 42.5,
              },
            ],
            'details': {'foo': 1},
          },
        ],
      }).toDomain();
      expect(result.session.isCompleted, isTrue);
      expect(result.session.type, SessionType.routine);
      expect(result.session.startedAt.isUtc, isFalse);
      expect(result.session.calories, 412.5);
      expect(result.session.setsFor('p1').single.weightKg, 40);
      expect(result.experience.levelUps, 1);
      final rec = result.recommendations.single;
      expect(rec.type, RecommendationType.progression);
      expect(rec.adjustments.single.parameters.weightKg, 42.5);
    });

    test('la página de la API se convierte en TrainingPage', () {
      final page = parseTrainingPage({
        'items': [
          {
            'id': 'p',
            'weekStart': '2026-10-12',
            'plannedSessions': 3,
            'intensity': 'HIGH',
            'minutesPerSession': 45,
            'status': 'ACTIVE',
            'notes': null,
            'completedSessions': 2,
            'compliance': 0.6667,
          },
        ],
        'page': 0,
        'size': 20,
        'totalItems': 21,
        'totalPages': 2,
      }, (j) => WeeklyPlanDto.fromJson(j).toDomain());
      expect(page.hasMore, isTrue);
      expect(page.totalItems, 21);
      final plan = page.items.single;
      expect(plan.weekStart, DateTime(2026, 10, 12));
      expect(plan.intensity, PlanIntensity.high);
    });
  });

  test('calorías estimadas con MET, peso y duración', () {
    const p = ExerciseParameters(sets: 3, reps: 10, restSeconds: 60);
    // 3 × 10 × 3 s + 2 × 60 s = 210 s.
    expect(p.estimatedDurationSeconds, 210);
    expect(
      p.estimatedCalories(met: 6, bodyWeightKg: 60),
      closeTo(6 * 60 * 210 / 3600, 0.001),
    );
    expect(
      const ExerciseParameters(
        targetDurationSeconds: 1800,
      ).estimatedCalories(met: 8),
      closeTo(8 * kDefaultBodyWeightKg * 0.5, 0.001),
    );
  });
}
