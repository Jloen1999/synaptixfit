import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/challenge_link_type.dart';
import 'package:synaptixfit/domain/enums/challenge_type.dart';
import 'package:synaptixfit/domain/enums/milestone_condition.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/challenges/challenge.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_draft.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_draft_validator.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_outcome.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_references.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/create_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/get_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_challenge_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/replace_milestones_use_case.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenge_form/bloc/challenge_form_bloc.dart';

import 'challenges_fixtures.dart';

class _Subjects extends Mock implements ListChallengeSubjectsUseCaseContract {}

class _Create extends Mock implements CreateChallengeUseCaseContract {}

class _Get extends Mock implements GetChallengeUseCaseContract {}

class _Replace extends Mock implements ReplaceMilestonesUseCaseContract {}

class _Account extends Mock implements GetAccountUseCaseContract {}

void main() {
  late _Subjects subjects;
  late _Create create;
  late _Get get;
  late _Replace replace;
  late _Account account;
  final now = DateTime(2026, 10, 18, 10);
  const algebra = ChallengeSubjectOption(id: 's1', name: 'Álgebra');

  setUpAll(() {
    registerFallbackValue(ChallengeDraft(title: 'x', endAt: DateTime(2026)));
    registerFallbackValue(<MilestoneDraft>[]);
  });

  setUp(() {
    subjects = _Subjects();
    create = _Create();
    get = _Get();
    replace = _Replace();
    account = _Account();
    when(() => subjects()).thenAnswer((_) async => const Success([algebra]));
  });

  ChallengeFormBloc build() => ChallengeFormBloc(
    listSubjects: subjects,
    createChallenge: create,
    getChallenge: get,
    replaceMilestones: replace,
    getAccount: account,
    now: () => now,
  );

  MilestoneFormItem item(
    String key, {
    List<String> deps = const [],
    MilestoneCondition condition = MilestoneCondition.all,
    int n = 1,
  }) => MilestoneFormItem(
    key: key,
    title: 'Tarea $key',
    dependsOnKeys: deps,
    condition: condition,
    conditionN: n,
  );

  final readyState = ChallengeFormState(
    status: ChallengeFormStatus.ready,
    title: 'Preparar el parcial',
    endAt: DateTime(2026, 10, 25, 23, 59),
    subjects: const [algebra],
  );

  blocTest<ChallengeFormBloc, ChallengeFormState>(
    'arranca con los valores recibidos y fecha de fin por defecto a 7 días',
    build: build,
    act: (b) => b.add(
      const ChallengeFormEvent.started(
        title: 'Repasar',
        subjectId: 's1',
        subjectName: 'Álgebra',
      ),
    ),
    expect: () => [
      ChallengeFormState(
        status: ChallengeFormStatus.ready,
        title: 'Repasar',
        subjectId: 's1',
        subjectName: 'Álgebra',
        endAt: DateTime(2026, 10, 25, 23, 59),
      ),
      ChallengeFormState(
        status: ChallengeFormStatus.ready,
        title: 'Repasar',
        subjectId: 's1',
        subjectName: 'Álgebra',
        endAt: DateTime(2026, 10, 25, 23, 59),
        subjects: const [algebra],
      ),
    ],
  );

  blocTest<ChallengeFormBloc, ChallengeFormState>(
    'quitar una tarea elimina las dependencias que apuntaban a ella',
    build: build,
    seed: () => readyState.copyWith(
      milestones: [
        item('a'),
        item('b'),
        item('c', deps: ['a', 'b'], condition: MilestoneCondition.xOfY, n: 2),
      ],
    ),
    act: (b) => b.add(const ChallengeFormEvent.milestoneRemoved('a')),
    expect: () => [
      readyState.copyWith(
        milestones: [
          item('b'),
          item('c', deps: ['b'], condition: MilestoneCondition.xOfY),
        ],
      ),
    ],
  );

  blocTest<ChallengeFormBloc, ChallengeFormState>(
    '«hacer en orden» quita las dependencias a medida y encadena al enviar',
    setUp: () => when(
      () => create(any()),
    ).thenAnswer((_) async => Success(ChallengesFixtures.challenge())),
    build: build,
    seed: () => readyState.copyWith(
      milestones: [
        item('a'),
        item('b', deps: ['a']),
        item('c', deps: ['a']),
      ],
    ),
    act: (b) => b
      ..add(const ChallengeFormEvent.inOrderToggled(true))
      ..add(const ChallengeFormEvent.submitted()),
    skip: 1,
    verify: (_) {
      final draft =
          verify(() => create(captureAny())).captured.single as ChallengeDraft;
      expect(draft.milestones.map((m) => m.dependsOn), [
        <int>[],
        [0],
        [1],
      ]);
    },
  );

  blocTest<ChallengeFormBloc, ChallengeFormState>(
    'enviar con dependencias en ciclo muestra dependencyCycle',
    build: build,
    seed: () => readyState.copyWith(
      milestones: [
        item('a', deps: ['b']),
        item('b', deps: ['a']),
      ],
    ),
    act: (b) => b.add(const ChallengeFormEvent.submitted()),
    expect: () => [
      isA<ChallengeFormState>().having(
        (s) => s.issue,
        'issue',
        ChallengeDraftIssue.dependencyCycle,
      ),
    ],
    verify: (_) => verifyNever(() => create(any())),
  );

  blocTest<ChallengeFormBloc, ChallengeFormState>(
    'enviar con título corto muestra titleTooShort',
    build: build,
    seed: () => readyState.copyWith(title: 'Leer'),
    act: (b) => b.add(const ChallengeFormEvent.submitted()),
    expect: () => [
      readyState.copyWith(
        title: 'Leer',
        issue: ChallengeDraftIssue.titleTooShort,
      ),
    ],
  );

  blocTest<ChallengeFormBloc, ChallengeFormState>(
    'crea el reto con dependencias por posición tras reordenar',
    setUp: () => when(
      () => create(any()),
    ).thenAnswer((_) async => Success(ChallengesFixtures.challenge(id: 'new'))),
    build: build,
    seed: () => readyState.copyWith(
      subjectId: 's1',
      link: const ChallengeLink(type: ChallengeLinkType.exam, entityId: 'd1'),
      milestones: [
        item('a'),
        item('b'),
        item('c', deps: ['a', 'b'], condition: MilestoneCondition.xOfY, n: 1),
      ],
    ),
    act: (b) => b
      ..add(const ChallengeFormEvent.milestoneMoved('c', -2))
      ..add(const ChallengeFormEvent.submitted()),
    skip: 3,
    expect: () => [
      isA<ChallengeFormState>().having(
        (s) => s.effect,
        'effect',
        const ChallengeFormEffect.saved(challengeId: 'new'),
      ),
      isA<ChallengeFormState>().having((s) => s.effect, 'effect', isNull),
    ],
    verify: (_) {
      final draft =
          verify(() => create(captureAny())).captured.single as ChallengeDraft;
      expect(draft.title, 'Preparar el parcial');
      expect(draft.type, ChallengeType.academic);
      expect(draft.subjectId, 's1');
      expect(draft.link?.entityId, 'd1');
      expect(draft.milestones.map((m) => m.title), [
        'Tarea c',
        'Tarea a',
        'Tarea b',
      ]);
      expect(draft.milestones.first.dependsOn, [1, 2]);
      expect(draft.milestones.first.condition, MilestoneCondition.xOfY);
      expect(draft.milestones.first.conditionN, 1);
    },
  );

  blocTest<ChallengeFormBloc, ChallengeFormState>(
    'un reto de fitness sin tareas envía el objetivo de sesiones',
    setUp: () => when(
      () => create(any()),
    ).thenAnswer((_) async => Success(ChallengesFixtures.challenge(id: 'new'))),
    build: build,
    seed: () => readyState.copyWith(type: ChallengeType.fitness),
    act: (b) => b
      ..add(const ChallengeFormEvent.sessionTargetChanged(12))
      ..add(const ChallengeFormEvent.submitted()),
    verify: (_) {
      final draft =
          verify(() => create(captureAny())).captured.single as ChallengeDraft;
      expect(draft.type, ChallengeType.fitness);
      expect(draft.sessionTarget, 12);
    },
  );

  blocTest<ChallengeFormBloc, ChallengeFormState>(
    'con tareas o en un reto académico el objetivo de sesiones no se envía',
    setUp: () => when(
      () => create(any()),
    ).thenAnswer((_) async => Success(ChallengesFixtures.challenge(id: 'new'))),
    build: build,
    seed: () => readyState.copyWith(
      type: ChallengeType.fitness,
      sessionTarget: 12,
      milestones: [item('a')],
    ),
    act: (b) => b.add(const ChallengeFormEvent.submitted()),
    verify: (b) {
      expect(b.state.showsSessionTarget, isFalse);
      expect(
        readyState.copyWith(sessionTarget: 12).showsSessionTarget,
        isFalse,
      );
      final draft =
          verify(() => create(captureAny())).captured.single as ChallengeDraft;
      expect(draft.sessionTarget, isNull);
    },
  );

  blocTest<ChallengeFormBloc, ChallengeFormState>(
    'un objetivo de sesiones fuera de 1..365 no se guarda',
    build: build,
    seed: () => readyState.copyWith(type: ChallengeType.fitness),
    act: (b) => b
      ..add(const ChallengeFormEvent.sessionTargetChanged(0))
      ..add(const ChallengeFormEvent.submitted()),
    skip: 1,
    expect: () => [
      readyState.copyWith(
        type: ChallengeType.fitness,
        sessionTarget: 0,
        issue: ChallengeDraftIssue.sessionTargetInvalid,
      ),
    ],
    verify: (_) => verifyNever(() => create(any())),
  );

  blocTest<ChallengeFormBloc, ChallengeFormState>(
    'si el servidor rechaza el reto emite el error y sigue editable',
    setUp: () => when(() => create(any())).thenAnswer(
      (_) async => const Failure(AppError.business('CHALLENGE_LINK_NOT_FOUND')),
    ),
    build: build,
    seed: () => readyState,
    act: (b) => b.add(const ChallengeFormEvent.submitted()),
    expect: () => [
      readyState.copyWith(status: ChallengeFormStatus.saving),
      readyState,
      readyState.copyWith(
        effect: const ChallengeFormEffect.failure(
          AppError.business('CHALLENGE_LINK_NOT_FOUND'),
        ),
      ),
      readyState,
    ],
  );

  group('editar tareas', () {
    final existing = ChallengesFixtures.challenge(
      milestones: [
        ChallengesFixtures.milestone('m1', completed: true, xpAwarded: 40),
        ChallengesFixtures.milestone('m2', dependencies: ['m1']),
      ],
    );

    blocTest<ChallengeFormBloc, ChallengeFormState>(
      'carga las tareas existentes con sus dependencias',
      setUp: () =>
          when(() => get('c1')).thenAnswer((_) async => Success(existing)),
      build: build,
      act: (b) => b.add(const ChallengeFormEvent.started(challengeId: 'c1')),
      skip: 1,
      expect: () => [
        isA<ChallengeFormState>()
            .having((s) => s.mode, 'mode', ChallengeFormMode.editMilestones)
            .having((s) => s.milestones.length, 'count', 2)
            // m2 depende solo de m1: es «en orden» y la cadena se rehace al
            // guardar.
            .having((s) => s.inOrder, 'inOrder', isTrue)
            .having((s) => s.milestones[1].dependsOnKeys, 'deps', isEmpty)
            .having((s) => s.milestones[0].completed, 'completed', true),
      ],
    );

    blocTest<ChallengeFormBloc, ChallengeFormState>(
      'guardar reemplaza las tareas y refresca la cuenta si cambia la XP',
      setUp: () {
        when(() => get('c1')).thenAnswer((_) async => Success(existing));
        when(() => replace('c1', any())).thenAnswer(
          (_) async => Success(
            ChallengeOutcome(
              challenge: existing,
              xpDelta: -40,
              challengeCompleted: false,
            ),
          ),
        );
        when(
          () => account(),
        ).thenAnswer((_) async => const Success(ChallengesFixtures.account));
      },
      build: build,
      act: (b) async {
        b.add(const ChallengeFormEvent.started(challengeId: 'c1'));
        await Future<void>.delayed(Duration.zero);
        b
          ..add(const ChallengeFormEvent.milestoneRemoved('m1'))
          ..add(const ChallengeFormEvent.submitted());
      },
      verify: (b) {
        final drafts =
            verify(() => replace('c1', captureAny())).captured.single
                as List<MilestoneDraft>;
        expect(drafts.single.id, 'm2');
        expect(drafts.single.dependsOn, isEmpty);
        verify(() => account()).called(1);
      },
    );
  });
}
