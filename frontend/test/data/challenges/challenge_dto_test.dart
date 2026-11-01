import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/challenges/dto/challenge_dto.dart';
import 'package:synaptixfit/data/remote_data_source/challenges/dto/challenge_reference_dto.dart';
import 'package:synaptixfit/data/remote_data_source/challenges/dto/challenge_request_dto.dart';
import 'package:synaptixfit/domain/enums/challenge_difficulty.dart';
import 'package:synaptixfit/domain/enums/challenge_link_type.dart';
import 'package:synaptixfit/domain/enums/challenge_status.dart';
import 'package:synaptixfit/domain/enums/challenge_type.dart';
import 'package:synaptixfit/domain/enums/milestone_condition.dart';
import 'package:synaptixfit/domain/enums/milestone_status.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/challenges/challenge.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_draft.dart';

void main() {
  final json = <String, dynamic>{
    'id': 'c1',
    'ownerId': 'u1',
    'owned': true,
    'ownerName': 'Ana',
    'title': 'Preparar el examen',
    'type': 'ACADEMIC',
    'goal': 'Aprobar',
    'visibility': 'FRIENDS',
    'difficulty': 'HIGH',
    'xpReward': 70,
    'xpAwarded': 0,
    'completed': false,
    'status': 'EXPIRED',
    'progress': 37.5,
    'startAt': '2026-10-01T08:00:00Z',
    'endAt': '2026-10-30T22:59:00Z',
    'subjectId': 's1',
    'linkedEntityType': 'EXAM',
    'linkedEntityId': 'd1',
    'currentStreak': 2,
    'bestStreak': 5,
    'lastActiveDay': '2026-10-17',
    'hasDependencies': true,
    'milestoneCount': 2,
    'completedMilestoneCount': 1,
    'milestones': [
      {
        'id': 'm2',
        'title': 'Segunda',
        'weight': 25.0,
        'order': 2,
        'progress': 0.0,
        'completed': false,
        'status': 'LOCKED',
        'dependencies': ['m1'],
        'conditionType': 'X_OF_Y',
        'conditionN': 1,
        'difficulty': 'LOW',
        'xpReward': 20,
        'xpAwarded': 0,
        'linkedEntityType': 'DELIVERY',
        'linkTitle': 'Práctica 2',
        'linkDueAt': '2026-11-02T09:00:00Z',
        'completedByLink': true,
        'linkedEntityId': 'b1',
        'fileId': 'f1',
      },
      {
        'id': 'm1',
        'title': 'Primera',
        'weight': 75.0,
        'order': 1,
        'progress': 100.0,
        'completed': true,
        'status': 'COMPLETED',
        'dependencies': <String>[],
        'conditionType': 'AND',
        'conditionN': 1,
        'difficulty': 'MEDIUM',
        'xpReward': 40,
        'xpAwarded': 40,
        'noteId': 'n1',
      },
    ],
    'originId': null,
    'createdAt': '2026-10-01T08:00:00Z',
  };

  test('ChallengeDto.toDomain mapea enums, fechas locales y ordena tareas', () {
    final challenge = ChallengeDto.fromJson(json).toDomain();

    expect(challenge.type, ChallengeType.academic);
    expect(challenge.visibility, Visibility.friends);
    expect(challenge.difficulty, ChallengeDifficulty.high);
    expect(challenge.status, ChallengeStatus.expired);
    expect(
      challenge.link,
      const ChallengeLink(type: ChallengeLinkType.exam, entityId: 'd1'),
    );
    expect(challenge.endAt, DateTime.utc(2026, 10, 30, 22, 59).toLocal());
    expect(challenge.endAt.isUtc, isFalse);
    expect(challenge.lastActiveDay, DateTime(2026, 10, 17));
    expect(challenge.milestones.map((m) => m.id), ['m1', 'm2']);
    expect(challenge.totalXpAwarded, 40);

    final second = challenge.milestones[1];
    expect(second.status, MilestoneStatus.locked);
    expect(second.condition, MilestoneCondition.xOfY);
    expect(second.difficulty, ChallengeDifficulty.low);
    expect(second.link?.type, ChallengeLinkType.delivery);
    expect(second.linkTitle, 'Práctica 2');
    expect(second.completedByLink, isTrue);
    expect(second.fileId, 'f1');
    expect(challenge.milestones.first.noteId, 'n1');
  });

  test('ChallengeDto mapea el objetivo de sesiones de entrenamiento', () {
    final fitness = ChallengeDto.fromJson({
      ...json,
      'type': 'FITNESS',
      'subjectId': null,
      'milestoneCount': 0,
      'completedMilestoneCount': 0,
      'milestones': <Object>[],
      'sessionTarget': 12,
      'sessionsCompleted': 4,
      'tracksTrainingSessions': true,
    }).toDomain();
    expect(fitness.sessionTarget, 12);
    expect(fitness.sessionsCompleted, 4);
    expect(fitness.tracksTrainingSessions, isTrue);

    // Sin los campos (respuestas antiguas) no hay objetivo ni cuenta sesiones.
    final legacy = ChallengeDto.fromJson(json).toDomain();
    expect(legacy.sessionTarget, isNull);
    expect(legacy.sessionsCompleted, 0);
    expect(legacy.tracksTrainingSessions, isFalse);
  });

  test('ChallengeOutcomeDto incluye XP y tareas desbloqueadas', () {
    final outcome = ChallengeOutcomeDto.fromJson({
      'challenge': json,
      'xpDelta': -40,
      'unlockedMilestoneIds': ['m2'],
      'challengeCompleted': false,
    }).toDomain();
    expect(outcome.xpDelta, -40);
    expect(outcome.unlockedMilestoneIds, ['m2']);
    expect(outcome.challenge.id, 'c1');
  });

  test('CreateChallengeRequestDto serializa el borrador para la API', () {
    final draft = ChallengeDraft(
      title: '  Reto con tareas ',
      type: ChallengeType.fitness,
      goal: '',
      visibility: Visibility.public,
      difficulty: ChallengeDifficulty.low,
      endAt: DateTime.utc(2026, 11, 1, 22, 59),
      link: const ChallengeLink(
        type: ChallengeLinkType.delivery,
        entityId: 'd',
      ),
      milestones: const [
        MilestoneDraft(title: 'Uno'),
        MilestoneDraft(
          title: 'Dos',
          dependsOn: [0],
          condition: MilestoneCondition.any,
          noteId: 'n1',
        ),
      ],
    );
    final body = CreateChallengeRequestDto.fromDomain(draft).toJson();

    expect(body['title'], 'Reto con tareas');
    expect(body['type'], 'FITNESS');
    expect(body.containsKey('goal'), isFalse);
    expect(body.containsKey('startAt'), isFalse);
    expect(body['visibility'], 'PUBLIC');
    expect(body['difficulty'], 'LOW');
    expect(body['endAt'], '2026-11-01T22:59:00.000Z');
    expect(body['linkedEntityType'], 'DELIVERY');
    final milestones = body['milestones'] as List;
    expect(milestones[0], {
      'title': 'Uno',
      'difficulty': 'MEDIUM',
      'dependsOn': <int>[],
    });
    expect(milestones[1]['dependsOn'], [0]);
    expect(milestones[1]['conditionType'], 'OR');
    expect(milestones[1]['noteId'], 'n1');
  });

  test('CreateChallengeRequestDto envía sessionTarget solo si lo hay', () {
    final draft = ChallengeDraft(
      title: 'Doce entrenos',
      type: ChallengeType.fitness,
      endAt: DateTime.utc(2026, 11, 1),
      sessionTarget: 12,
    );
    expect(
      CreateChallengeRequestDto.fromDomain(draft).toJson()['sessionTarget'],
      12,
    );
    expect(
      CreateChallengeRequestDto.fromDomain(
        draft.copyWith(sessionTarget: null),
      ).toJson().containsKey('sessionTarget'),
      isFalse,
    );
  });

  test('UpdateChallengeRequestDto cambia o quita el objetivo de sesiones', () {
    expect(
      UpdateChallengeRequestDto.fromDomain(
        const ChallengeChanges(sessionTarget: 8),
      ).toJson(),
      {'sessionTarget': 8},
    );
    expect(
      UpdateChallengeRequestDto.fromDomain(
        const ChallengeChanges(sessionTarget: 8, clearSessionTarget: true),
      ).toJson(),
      {'clearSessionTarget': true},
    );
  });

  test('UpdateChallengeRequestDto envía clearSubject y omite nulos', () {
    final body = UpdateChallengeRequestDto.fromDomain(
      const ChallengeChanges(
        visibility: Visibility.friends,
        clearSubject: true,
      ),
    ).toJson();
    expect(body, {'visibility': 'FRIENDS', 'clearSubject': true});
  });

  test('ChallengeDeadlineDto: examen → EXAM, resto → DELIVERY', () {
    final exam = ChallengeDeadlineDto.fromJson({
      'id': 'd1',
      'title': 'Parcial',
      'type': 'EXAM',
      'dueAt': '2026-11-01T09:00:00Z',
    }).toDomain();
    final work = ChallengeDeadlineDto.fromJson({
      'id': 'd2',
      'title': 'Práctica',
      'type': 'ASSIGNMENT',
      'dueAt': '2026-11-02T09:00:00Z',
    }).toDomain();
    expect(exam.type, ChallengeLinkType.exam);
    expect(work.type, ChallengeLinkType.delivery);
  });

  test('ChallengeDto lee UPCOMING y el vínculo que completa el reto', () {
    final c = ChallengeDto.fromJson({
      ...json,
      'status': 'UPCOMING',
      'linkTitle': 'Examen final',
      'completedByLink': true,
      'milestones': <dynamic>[],
      'milestoneCount': 0,
    }).toDomain();
    expect(c.status, ChallengeStatus.upcoming);
    expect(c.linkTitle, 'Examen final');
    expect(c.completedByLink, isTrue);
  });
}
