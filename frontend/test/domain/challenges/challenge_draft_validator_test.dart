import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/challenge_type.dart';
import 'package:synaptixfit/domain/enums/milestone_condition.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_draft.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_draft_validator.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_references.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/challenge_references_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/challenges_repository_contract.dart';
import 'package:synaptixfit/domain/enums/challenge_link_type.dart';
import 'package:synaptixfit/domain/use_cases/challenges/create_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_challenge_link_targets_use_case.dart';

class _MockRepo extends Mock implements ChallengesRepositoryContract {}

class _MockRefs extends Mock implements ChallengeReferencesRepositoryContract {}

MilestoneDraft _m(
  String title, {
  double? weight,
  List<int> deps = const [],
  MilestoneCondition condition = MilestoneCondition.all,
  int? n,
}) => MilestoneDraft(
  title: title,
  weight: weight,
  dependsOn: deps,
  condition: condition,
  conditionN: n,
);

void main() {
  final end = DateTime(2026, 11, 1);

  group('ChallengeDraftValidator', () {
    test('acepta un reto sin tareas', () {
      expect(
        ChallengeDraftValidator.validate(
          ChallengeDraft(title: 'Leer cada día', endAt: end),
        ),
        isNull,
      );
    });

    test('el objetivo de sesiones va de 1 a 365 y solo en fitness', () {
      ChallengeDraftIssue? check(int target, ChallengeType type) =>
          ChallengeDraftValidator.validate(
            ChallengeDraft(
              title: 'Entrenar cada semana',
              type: type,
              endAt: end,
              sessionTarget: target,
            ),
          );
      expect(check(1, ChallengeType.fitness), isNull);
      expect(check(365, ChallengeType.fitness), isNull);
      expect(
        check(0, ChallengeType.fitness),
        ChallengeDraftIssue.sessionTargetInvalid,
      );
      expect(
        check(366, ChallengeType.fitness),
        ChallengeDraftIssue.sessionTargetInvalid,
      );
      expect(
        check(10, ChallengeType.academic),
        ChallengeDraftIssue.sessionTargetInvalid,
      );
      expect(
        ChallengeDraftIssue.sessionTargetInvalid.asError,
        const AppError.validation(),
      );
    });

    test('rechaza título corto y fechas invertidas', () {
      expect(
        ChallengeDraftValidator.validate(
          ChallengeDraft(title: 'Leer', endAt: end),
        ),
        ChallengeDraftIssue.titleTooShort,
      );
      expect(
        ChallengeDraftValidator.validate(
          ChallengeDraft(
            title: 'Leer cada día',
            startAt: DateTime(2026, 12, 1),
            endAt: end,
          ),
        ),
        ChallengeDraftIssue.invalidDates,
      );
    });

    test('pesos: todos o ninguno, entre 0 y 100 y sumando 100', () {
      expect(
        ChallengeDraftValidator.validateMilestones([_m('Uno'), _m('Dos')]),
        isNull,
      );
      expect(
        ChallengeDraftValidator.validateMilestones([
          _m('Uno', weight: 50),
          _m('Dos'),
        ]),
        ChallengeDraftIssue.weightsIncomplete,
      );
      expect(
        ChallengeDraftValidator.validateMilestones([
          _m('Uno', weight: 0),
          _m('Dos', weight: 100),
        ]),
        ChallengeDraftIssue.weightOutOfRange,
      );
      expect(
        ChallengeDraftValidator.validateMilestones([
          _m('Uno', weight: 60),
          _m('Dos', weight: 30),
        ]),
        ChallengeDraftIssue.weightsSum,
      );
      expect(
        ChallengeDraftValidator.validateMilestones([
          _m('Uno', weight: 33.33),
          _m('Dos', weight: 33.33),
          _m('Tres', weight: 33.33),
        ]),
        isNull,
      );
    });

    test('dependencias: propias, inexistentes, duplicadas y ciclos', () {
      expect(
        ChallengeDraftValidator.validateMilestones([
          _m('Uno', deps: [0]),
        ]),
        ChallengeDraftIssue.dependencyInvalid,
      );
      expect(
        ChallengeDraftValidator.validateMilestones([
          _m('Uno', deps: [3]),
        ]),
        ChallengeDraftIssue.dependencyInvalid,
      );
      expect(
        ChallengeDraftValidator.validateMilestones([
          _m('Uno'),
          _m('Dos', deps: [0, 0]),
        ]),
        ChallengeDraftIssue.dependencyInvalid,
      );
      expect(
        ChallengeDraftValidator.validateMilestones([
          _m('Uno', deps: [2]),
          _m('Dos', deps: [0]),
          _m('Tres', deps: [1]),
        ]),
        ChallengeDraftIssue.dependencyCycle,
      );
    });

    test('X de Y exige N entre 1 y el número de dependencias', () {
      expect(
        ChallengeDraftValidator.validateMilestones([
          _m('Uno'),
          _m('Dos'),
          _m('Tres', deps: [0, 1], condition: MilestoneCondition.xOfY, n: 3),
        ]),
        ChallengeDraftIssue.conditionInvalid,
      );
      expect(
        ChallengeDraftValidator.validateMilestones([
          _m('Uno'),
          _m('Dos'),
          _m('Tres', deps: [0, 1], condition: MilestoneCondition.xOfY, n: 1),
        ]),
        isNull,
      );
    });

    test('más de 12 tareas y adjunto doble', () {
      expect(
        ChallengeDraftValidator.validateMilestones([
          for (var i = 0; i < 13; i++) _m('Tarea $i'),
        ]),
        ChallengeDraftIssue.tooManyMilestones,
      );
      expect(
        ChallengeDraftValidator.validateMilestones([
          const MilestoneDraft(title: 'Uno', noteId: 'n', fileId: 'f'),
        ]),
        ChallengeDraftIssue.attachmentConflict,
      );
    });

    test('autoWeights reparte 100 y el último absorbe el resto', () {
      expect(ChallengeDraftValidator.autoWeights(3), [33.33, 33.33, 33.34]);
      expect(ChallengeDraftValidator.autoWeights(0), isEmpty);
    });
  });

  group('CreateChallengeUseCase', () {
    test('no llama al repositorio si el borrador no es válido', () async {
      final repo = _MockRepo();
      final result = await CreateChallengeUseCase(repo)(
        ChallengeDraft(
          title: 'Reto válido',
          endAt: end,
          milestones: [_m('Uno', weight: 10), _m('Dos', weight: 10)],
        ),
      );
      expect(
        result.errorOrNull,
        const AppError.business('MILESTONE_WEIGHTS_INVALID'),
      );
      verifyZeroInteractions(repo);
    });
  });

  group('ListChallengeLinkTargetsUseCase', () {
    test('pide 4 semanas desde ahora y ordena por fecha', () async {
      final refs = _MockRefs();
      final now = DateTime(2026, 10, 18, 10);
      final later = ChallengeLinkOption(
        id: 'b',
        type: ChallengeLinkType.block,
        title: 'Bloque',
        at: DateTime(2026, 10, 25),
      );
      final sooner = ChallengeLinkOption(
        id: 'd',
        type: ChallengeLinkType.exam,
        title: 'Examen',
        at: DateTime(2026, 10, 20),
      );
      when(
        () => refs.linkTargets(
          subjectId: any(named: 'subjectId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Success([later, sooner]));

      final result = await ListChallengeLinkTargetsUseCase(
        refs,
        now: () => now,
      )(subjectId: 's1');

      expect(result.valueOrNull, [sooner, later]);
      verify(
        () => refs.linkTargets(
          subjectId: 's1',
          from: now,
          to: now.add(const Duration(days: 28)),
        ),
      ).called(1);
    });
  });
}
