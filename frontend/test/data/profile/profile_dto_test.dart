import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/profile/dto/academic_profile_dto.dart';
import 'package:synaptixfit/data/remote_data_source/profile/dto/catalog_dto.dart';
import 'package:synaptixfit/data/remote_data_source/profile/dto/notification_preferences_dto.dart';
import 'package:synaptixfit/data/remote_data_source/profile/dto/profile_summary_dto.dart';
import 'package:synaptixfit/data/remote_data_source/profile/dto/wellness_history_dto.dart';
import 'package:synaptixfit/data/remote_data_source/profile/dto/wellness_profile_dto.dart';
import 'package:synaptixfit/domain/enums/profile/activity_level.dart';
import 'package:synaptixfit/domain/enums/profile/fitness_goal.dart';
import 'package:synaptixfit/domain/enums/profile/goal_suggestion_source.dart';
import 'package:synaptixfit/domain/enums/profile/notification_category.dart';
import 'package:synaptixfit/domain/enums/profile/notification_mode.dart';
import 'package:synaptixfit/domain/enums/profile/onboarding_step.dart';
import 'package:synaptixfit/domain/enums/profile/sex.dart';
import 'package:synaptixfit/domain/enums/profile/study_modality.dart';
import 'package:synaptixfit/domain/models/profile/academic_profile.dart';
import 'package:synaptixfit/domain/models/profile/notification_preferences.dart';
import 'package:synaptixfit/domain/models/profile/wellness_profile.dart';

void main() {
  group('ProfileSummaryDto', () {
    test('mapea enums de la API, fechas y pasos pendientes', () {
      final summary = ProfileSummaryDto.fromJson({
        'wellness': {
          'age': 21,
          'sex': 'NON_BINARY',
          'weightKg': 70,
          'heightCm': 175.5,
          'bmi': 22.7,
          'activityLevel': 'HIGH',
          'primaryGoal': 'METABOLIC_CONDITIONING',
          'equipment': ['barra'],
          'availableDays': [5, 1, 3],
          'minutesPerSession': 60,
          'onboardingCompleted': false,
        },
        'academic': {
          'university': 'UGR',
          'degree': 'Informática',
          'semester': 3,
          'modality': 'HYBRID',
          'targetGpa': 4,
          'classesStartDate': '2026-09-15',
          'classesEndDate': '2027-01-20',
        },
        'degrees': [
          {
            'degree': {'id': 'd1', 'name': 'Informática'},
            'linkedAt': '2026-09-01T10:00:00Z',
          },
        ],
        'onboarding': {
          'completed': false,
          'pendingSteps': ['SUBJECTS', 'UNKNOWN_STEP'],
        },
      }).toDomain();

      final wellness = summary.wellness!;
      expect(wellness.sex, Sex.nonBinary);
      expect(wellness.weightKg, 70.0);
      expect(wellness.activityLevel, ActivityLevel.high);
      expect(wellness.primaryGoal, FitnessGoal.metabolicConditioning);
      expect(wellness.availableDays, [1, 3, 5]);

      final academic = summary.academic!;
      expect(academic.modality, StudyModality.hybrid);
      expect(academic.targetGpa, 4.0);
      expect(academic.classesStartDate, DateTime(2026, 9, 15));

      expect(summary.degrees.single.degree.name, 'Informática');
      expect(summary.degrees.single.linkedAt!.isUtc, isFalse);
      expect(summary.onboarding.pendingSteps, [OnboardingStep.subjects]);
    });

    test('sin perfiles devuelve nulos', () {
      final summary = ProfileSummaryDto.fromJson({
        'degrees': <Object>[],
        'onboarding': {'completed': true, 'pendingSteps': <String>[]},
      }).toDomain();
      expect(summary.wellness, isNull);
      expect(summary.academic, isNull);
      expect(summary.onboarding.completed, isTrue);
    });
  });

  test('wellnessDraftToJson usa los valores de la API', () {
    final json = wellnessDraftToJson(
      const WellnessProfileDraft(
        age: 20,
        sex: Sex.preferNotToSay,
        weightKg: 65.5,
        heightCm: 170,
        activityLevel: ActivityLevel.sedentary,
        primaryGoal: FitnessGoal.strengthEndurance,
        equipment: ['mancuerna'],
        availableDays: [7, 2],
        minutesPerSession: 30,
      ),
    );
    expect(json['sex'], 'PREFER_NOT_TO_SAY');
    expect(json['activityLevel'], 'SEDENTARY');
    expect(json['primaryGoal'], 'STRENGTH_ENDURANCE');
    expect(json['availableDays'], [2, 7]);
  });

  test('academicDraftToJson omite vacíos y formatea fechas', () {
    final json = academicDraftToJson(
      AcademicProfileDraft(
        degreeId: 'd1',
        modality: StudyModality.inPerson,
        classesStartDate: DateTime(2026, 2, 3),
      ),
    );
    expect(json, {
      'degreeId': 'd1',
      'modality': 'IN_PERSON',
      'classesStartDate': '2026-02-03',
    });
  });

  test('UserCatalogSubjectDto marca como añadida solo si está activa', () {
    Map<String, dynamic> item({String? userSubjectId, bool? active}) => {
      'subject': {
        'id': 'c1',
        'name': 'Cálculo',
        'course': 1,
        'semester': 1,
        'credits': 6,
      },
      'userSubjectId': userSubjectId,
      'active': active,
    };
    final page = UserCatalogSubjectPageDto.fromJson({
      'items': [
        item(),
        item(userSubjectId: 'u1', active: true),
        item(userSubjectId: 'u2', active: false),
      ],
      'page': 0,
      'size': 30,
      'totalItems': 3,
      'totalPages': 1,
    }).toDomain();
    expect(page.items.map((s) => s.alreadyAdded), [false, true, false]);
    expect(page.items.first.id, 'c1');
    expect(page.items.first.credits, 6.0);
    expect(page.hasMore, isFalse);
  });

  test('GoalSuggestionsDto descarta objetivos desconocidos', () {
    final suggestions = GoalSuggestionsDto.fromJson({
      'source': 'AI',
      'suggestions': [
        {'goal': 'POWER', 'label': 'Potencia', 'reason': 'Porque sí'},
        {'goal': 'FLYING', 'label': '?'},
      ],
    }).toDomain();
    expect(suggestions.source, GoalSuggestionSource.ai);
    expect(suggestions.suggestions.single.goal, FitnessGoal.power);
    expect(
      GoalSuggestionsDto.fromJson({'source': 'RULES'}).toDomain().source,
      GoalSuggestionSource.rules,
    );
  });

  test('WeightRecordDto convierte el instante a hora local', () {
    final record = WeightRecordDto.fromJson({
      'id': 'w1',
      'weightKg': 61,
      'recordedAt': '2026-10-01T08:00:00Z',
    }).toDomain();
    expect(record.weightKg, 61.0);
    expect(record.recordedAt.isUtc, isFalse);
    expect(record.recordedAt.toUtc(), DateTime.utc(2026, 10, 1, 8));
  });

  group('NotificationPreferences', () {
    test('ida y vuelta con la API', () {
      final prefs = NotificationPreferencesDto.fromJson({
        'activeCategories': ['ACADEMIC', 'SOCIAL', 'OTHER'],
        'quietHoursStart': '22:30:00',
        'quietHoursEnd': '07:00',
        'dailyLimit': 5,
        'mode': 'EXAMS',
      }).toDomain();
      expect(prefs.activeCategories, {
        NotificationCategory.academic,
        NotificationCategory.social,
      });
      expect(prefs.quietHoursStart, const ClockTime(hour: 22, minute: 30));
      expect(prefs.mode, NotificationMode.exams);

      final json = notificationPreferencesToJson(prefs);
      expect(json['activeCategories'], ['SOCIAL', 'ACADEMIC']);
      expect(json['quietHoursStart'], '22:30:00');
      expect(json['quietHoursEnd'], '07:00:00');
      expect(json['mode'], 'EXAMS');
    });

    test('sin horas de silencio envía nulos', () {
      final json = notificationPreferencesToJson(
        const NotificationPreferences(
          activeCategories: {},
          dailyLimit: 0,
          mode: NotificationMode.rest,
        ),
      );
      expect(json['quietHoursStart'], isNull);
      expect(json['quietHoursEnd'], isNull);
    });
  });
}
