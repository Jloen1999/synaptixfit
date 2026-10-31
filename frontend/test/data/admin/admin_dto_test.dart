import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/admin/dto/admin_exercise_dto.dart';
import 'package:synaptixfit/data/remote_data_source/admin/dto/admin_json.dart';
import 'package:synaptixfit/data/remote_data_source/admin/dto/admin_user_dto.dart';
import 'package:synaptixfit/data/remote_data_source/admin/dto/admin_user_stats_dto.dart';
import 'package:synaptixfit/data/remote_data_source/admin/dto/audit_entry_dto.dart';
import 'package:synaptixfit/data/remote_data_source/admin/dto/platform_metrics_dto.dart';
import 'package:synaptixfit/domain/enums/admin/admin_audit_action.dart';
import 'package:synaptixfit/domain/enums/admin/admin_audit_entity.dart';
import 'package:synaptixfit/domain/enums/admin/admin_erasure_mode.dart';
import 'package:synaptixfit/domain/enums/admin/admin_exercise_difficulty.dart';
import 'package:synaptixfit/domain/enums/admin/admin_exercise_modality.dart';
import 'package:synaptixfit/domain/enums/admin/admin_exercise_purpose.dart';
import 'package:synaptixfit/domain/enums/admin/admin_measurement_type.dart';
import 'package:synaptixfit/domain/enums/admin/admin_report_type.dart';
import 'package:synaptixfit/domain/enums/admin/admin_timeline_type.dart';
import 'package:synaptixfit/domain/enums/admin/admin_user_sort.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/admin/admin_exercise.dart';

void main() {
  group('enums', () {
    test('apiValue en UPPER_SNAKE_CASE y vuelta', () {
      expect(AdminExercisePurpose.maxStrength.apiValue, 'MAX_STRENGTH');
      expect(
        AdminExercisePurpose.fromApi('METABOLIC_CONDITIONING'),
        AdminExercisePurpose.metabolicConditioning,
      );
      expect(AdminAuditAction.activateShadowban.apiValue, 'ACTIVATE_SHADOWBAN');
      expect(AdminAuditEntity.platformSettings.apiValue, 'PLATFORM_SETTINGS');
      expect(AdminUserSort.fullName.apiValue, 'NAME');
      expect(AdminUserSort.createdAt.apiValue, 'CREATED_AT');
    });

    test('valores desconocidos caen en el valor por defecto', () {
      expect(AdminAuditAction.fromApi('NUEVA_ACCION'), AdminAuditAction.other);
      expect(AdminTimelineType.fromApi(null), AdminTimelineType.adminAction);
      expect(AdminMeasurementType.listFromApi(['TIME', 'RARO', 'WEIGHT']), [
        AdminMeasurementType.time,
        AdminMeasurementType.weight,
      ]);
    });
  });

  test('AdminJson.page convierte PageResponse', () {
    final page = AdminJson.page({
      'items': [
        {'id': 'a'},
        {'id': 'b'},
      ],
      'page': 1,
      'size': 2,
      'totalItems': 5,
      'totalPages': 3,
    }, (json) => json['id'] as String);
    expect(page.items, ['a', 'b']);
    expect(page.hasPrevious, isTrue);
    expect(page.hasNext, isTrue);
    expect(page.totalItems, 5);
  });

  test('AdminUserDetailDto mapea cuenta, perfiles y fechas', () {
    final detail = AdminUserDetailDto.fromJson({
      'account': {
        'id': 'u1',
        'email': 'ana@uni.es',
        'fullName': 'Ana',
        'role': 'ADMIN',
        'level': 4,
        'levelXp': 10,
        'levelThreshold': 400,
        'totalXp': 610,
        'streak': 3,
        'privacy': 'FRIENDS',
        'shadowbanned': true,
        'hasPassword': true,
        'googleLinked': false,
        'deleted': false,
        'createdAt': '2026-09-01T08:30:00Z',
      },
      'wellbeingProfile': {'age': 21, 'weightKg': 70, 'bmi': 22.4},
      'academicProfile': {
        'degree': 'Informática',
        'classesStart': '2026-09-15',
      },
    }).toDomain();

    expect(detail.account.role, UserRole.admin);
    expect(detail.account.privacy, Visibility.friends);
    expect(detail.account.shadowbanned, isTrue);
    expect(detail.account.createdAt, DateTime.utc(2026, 9, 1, 8, 30).toLocal());
    expect(detail.wellbeingProfile!.weightKg, 70.0);
    expect(detail.academicProfile!.classesStart, DateTime(2026, 9, 15));
  });

  test('ErasureReportDto y métricas con valores por defecto', () {
    final report = ErasureReportDto.fromJson({
      'userId': 'u1',
      'mode': 'ANONYMIZED',
      'deletedRecords': 12,
    }).toDomain();
    expect(report.mode, AdminErasureMode.anonymized);
    expect(report.deletedRecords, 12);
    expect(report.storedFiles, 0);

    final metrics = PlatformMetricsDto.fromJson({'totalUsers': 9}).toDomain();
    expect(metrics.totalUsers, 9);
    expect(metrics.activeUsersToday, 0);

    final day = DailyActivityDto.fromJson({
      'date': '2026-10-02',
      'signups': 2,
    }).toDomain();
    expect(day.date, DateTime(2026, 10, 2));
  });

  test('timeline, auditoría y reportes', () {
    final entry = AdminTimelineEntryDto.fromJson({
      'occurredAt': '2026-10-01T10:00:00Z',
      'type': 'BADGE_EARNED',
      'title': 'Constante',
    }).toDomain();
    expect(entry.type, AdminTimelineType.badgeEarned);

    final audit = AuditEntryDto.fromJson({
      'id': 'a1',
      'action': 'DELETE_EXERCISE',
      'entityType': 'EXERCISE',
      'details': {
        'name': 'Sentadilla',
        'fields': ['met'],
      },
      'createdAt': '2026-10-01T10:00:00Z',
    }).toDomain();
    expect(audit.action, AdminAuditAction.deleteExercise);
    expect(audit.entityType, AdminAuditEntity.exercise);
    expect(audit.details['name'], 'Sentadilla');

    final report = ReportedContentDto.fromJson({
      'type': 'COMMENT',
      'id': 'c1',
      'postId': 'p1',
      'content': 'spam',
    }).toDomain();
    expect(report.type, AdminReportType.comment);
    expect(report.postId, 'p1');
  });

  test('AdminExerciseDto mapea enums y catálogos', () {
    final exercise = AdminExerciseDto.fromJson({
      'id': 'e1',
      'name': 'Sentadilla',
      'difficulty': 'ADVANCED',
      'modality': 'AEROBIC',
      'purposes': ['POWER', 'STABILITY'],
      'measurementTypes': ['REPETITIONS'],
      'circuit': true,
      'active': false,
      'met': 7,
      'bodyParts': [
        {'id': 1, 'name': 'Piernas'},
      ],
    }).toDomain();
    expect(exercise.difficulty, AdminExerciseDifficulty.advanced);
    expect(exercise.modality, AdminExerciseModality.aerobic);
    expect(exercise.purposes, [
      AdminExercisePurpose.power,
      AdminExercisePurpose.stability,
    ]);
    expect(exercise.met, 7.0);
    expect(exercise.active, isFalse);
    expect(exercise.bodyParts.single.name, 'Piernas');
  });

  test('AdminExerciseRequest limpia el borrador para la API', () {
    final body = AdminExerciseRequest.fromDraft(
      const AdminExerciseDraft(
        name: '  Plancha ',
        description: ' ',
        instructions: ['Apoya antebrazos', '  ', ' Aguanta '],
        difficulty: AdminExerciseDifficulty.intermediate,
        purposes: {AdminExercisePurpose.stability},
        modality: AdminExerciseModality.mobility,
        measurementTypes: {AdminMeasurementType.time},
        met: 3.5,
        bodyPartIds: {4},
      ),
    );
    expect(body['name'], 'Plancha');
    expect(body['description'], isNull);
    expect(body['instructions'], ['Apoya antebrazos', 'Aguanta']);
    expect(body['difficulty'], 'INTERMEDIATE');
    expect(body['purposes'], ['STABILITY']);
    expect(body['modality'], 'MOBILITY');
    expect(body['measurementTypes'], ['TIME']);
    expect(body['met'], 3.5);
    expect(body['gifUrl'], isNull);
    expect(body['bodyPartIds'], [4]);
    // Nombres en otros idiomas: vacíos como nulos (se muestran en español).
    expect(body['translations'], {'en': null, 'fr': null, 'pt': null});
  });

  test('AdminExerciseRequest envía los nombres revisados y omite los no '
      'cargados', () {
    final body = AdminExerciseRequest.fromDraft(
      const AdminExerciseDraft(
        name: 'Plancha',
        translations: AdminExerciseNames(en: ' Front plank ', pt: 'Prancha'),
      ),
    );
    expect(body['translations'], {
      'en': 'Front plank',
      'fr': null,
      'pt': 'Prancha',
    });
    final untouched = AdminExerciseRequest.fromDraft(
      const AdminExerciseDraft(name: 'Plancha', translations: null),
    );
    expect(untouched.containsKey('translations'), isFalse);
    expect(
      AdminExerciseNamesDto.fromJson(const {'en': 'Front plank'}).toDomain(),
      const AdminExerciseNames(en: 'Front plank'),
    );
  });

  test('AdminExerciseDraft valida los límites de la API', () {
    expect(const AdminExerciseDraft(name: 'Ok', met: 6).isValid, isTrue);
    expect(const AdminExerciseDraft(name: 'x', met: 6).isValid, isFalse);
    expect(const AdminExerciseDraft(name: 'Ok', met: 0.5).isValid, isFalse);
    expect(const AdminExerciseDraft(name: 'Ok', met: 26).isValid, isFalse);
    expect(
      AdminExerciseDraft(
        name: 'Ok',
        instructions: List.filled(31, 'paso'),
      ).isValid,
      isFalse,
    );
  });
}
