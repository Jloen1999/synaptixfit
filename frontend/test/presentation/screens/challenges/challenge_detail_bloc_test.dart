import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/milestone_status.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_draft.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_outcome.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_progress_entry.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_references.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/clone_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/delete_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/get_challenge_file_url_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/get_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_challenge_progress_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_challenge_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/record_challenge_progress_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/reorder_milestones_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/set_challenge_completion_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/set_milestone_completion_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/update_challenge_use_case.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenge_detail/bloc/challenge_detail_bloc.dart';

import 'challenges_fixtures.dart';

class _Get extends Mock implements GetChallengeUseCaseContract {}

class _Progress extends Mock implements ListChallengeProgressUseCaseContract {}

class _Subjects extends Mock implements ListChallengeSubjectsUseCaseContract {}

class _SetCompletion extends Mock
    implements SetChallengeCompletionUseCaseContract {}

class _SetMilestone extends Mock
    implements SetMilestoneCompletionUseCaseContract {}

class _Record extends Mock implements RecordChallengeProgressUseCaseContract {}

class _Delete extends Mock implements DeleteChallengeUseCaseContract {}

class _Clone extends Mock implements CloneChallengeUseCaseContract {}

class _Update extends Mock implements UpdateChallengeUseCaseContract {}

class _Reorder extends Mock implements ReorderMilestonesUseCaseContract {}

class _FileUrl extends Mock implements GetChallengeFileUrlUseCaseContract {}

class _Account extends Mock implements GetAccountUseCaseContract {}

void main() {
  late _Get get;
  late _Progress progress;
  late _Subjects subjects;
  late _SetCompletion setCompletion;
  late _SetMilestone setMilestone;
  late _Record record;
  late _Delete delete;
  late _Clone clone;
  late _Update update;
  late _Reorder reorder;
  late _FileUrl fileUrl;
  late _Account account;

  final m1 = ChallengesFixtures.milestone('m1');
  final m2 = ChallengesFixtures.milestone(
    'm2',
    status: MilestoneStatus.locked,
    dependencies: ['m1'],
  );
  final challenge = ChallengesFixtures.challenge(
    subjectId: 's1',
    milestones: [m1, m2],
  );
  final entry = ChallengeProgressEntry(
    id: 'p1',
    amount: 20,
    recordedAt: DateTime(2026, 10, 10),
  );

  setUpAll(() => registerFallbackValue(const ChallengeChanges()));

  setUp(() {
    get = _Get();
    progress = _Progress();
    subjects = _Subjects();
    setCompletion = _SetCompletion();
    setMilestone = _SetMilestone();
    record = _Record();
    delete = _Delete();
    clone = _Clone();
    update = _Update();
    reorder = _Reorder();
    fileUrl = _FileUrl();
    account = _Account();
    when(() => get('c1')).thenAnswer((_) async => Success(challenge));
    when(() => progress(any())).thenAnswer((_) async => Success([entry]));
    when(() => subjects()).thenAnswer(
      (_) async =>
          const Success([ChallengeSubjectOption(id: 's1', name: 'Álgebra')]),
    );
    when(
      () => account(),
    ).thenAnswer((_) async => const Success(ChallengesFixtures.account));
  });

  ChallengeDetailBloc build() => ChallengeDetailBloc(
    getChallenge: get,
    listProgress: progress,
    listSubjects: subjects,
    setCompletion: setCompletion,
    setMilestoneCompletion: setMilestone,
    recordProgress: record,
    deleteChallenge: delete,
    cloneChallenge: clone,
    updateChallenge: update,
    reorderMilestones: reorder,
    getFileUrl: fileUrl,
    getAccount: account,
  );

  final ready = ChallengeDetailState(
    status: ChallengeDetailStatus.ready,
    challenge: challenge,
  );

  blocTest<ChallengeDetailBloc, ChallengeDetailState>(
    'carga el reto, su historial y el nombre de la asignatura',
    build: build,
    act: (b) => b.add(const ChallengeDetailEvent.started('c1')),
    expect: () => [
      const ChallengeDetailState(),
      ready,
      ready.copyWith(history: [entry], subjectName: 'Álgebra'),
    ],
  );

  blocTest<ChallengeDetailBloc, ChallengeDetailState>(
    'emite failure si el reto no existe',
    setUp: () => when(() => get('c1')).thenAnswer(
      (_) async => const Failure(AppError.business('CHALLENGE_NOT_FOUND')),
    ),
    build: build,
    act: (b) => b.add(const ChallengeDetailEvent.started('c1')),
    expect: () => [
      const ChallengeDetailState(),
      const ChallengeDetailState(
        status: ChallengeDetailStatus.failure,
        error: AppError.business('CHALLENGE_NOT_FOUND'),
      ),
    ],
  );

  blocTest<ChallengeDetailBloc, ChallengeDetailState>(
    'completar una tarea actualiza el reto, refresca la cuenta y avisa del desbloqueo',
    setUp: () {
      final updated = challenge.copyWith(
        milestones: [
          ChallengesFixtures.milestone('m1', completed: true),
          m2.copyWith(status: MilestoneStatus.available),
        ],
      );
      when(() => setMilestone('c1', 'm1', completed: true)).thenAnswer(
        (_) async => Success(
          ChallengeOutcome(
            challenge: updated,
            xpDelta: 40,
            unlockedMilestoneIds: const ['m2'],
            challengeCompleted: false,
          ),
        ),
      );
    },
    build: build,
    seed: () => ready,
    act: (b) => b.add(const ChallengeDetailEvent.milestoneToggled('m1')),
    expect: () => [
      ready.copyWith(busyMilestoneId: 'm1'),
      ready.copyWith(busyMilestoneId: 'm1', busy: true),
      isA<ChallengeDetailState>()
          .having((s) => s.busy, 'busy', false)
          .having((s) => s.challenge!.milestones.first.completed, 'done', true),
      isA<ChallengeDetailState>().having(
        (s) => s.effect,
        'effect',
        const ChallengeDetailEffect.outcome(
          xpDelta: 40,
          unlockedTitles: ['Tarea m2'],
          challengeCompleted: false,
          account: ChallengesFixtures.account,
        ),
      ),
      isA<ChallengeDetailState>().having((s) => s.effect, 'effect', isNull),
    ],
  );

  blocTest<ChallengeDetailBloc, ChallengeDetailState>(
    'una tarea bloqueada propaga el error MILESTONE_LOCKED',
    setUp: () =>
        when(() => setMilestone('c1', 'm2', completed: true)).thenAnswer(
          (_) async => const Failure(AppError.business('MILESTONE_LOCKED')),
        ),
    build: build,
    seed: () => ready,
    act: (b) => b.add(const ChallengeDetailEvent.milestoneToggled('m2')),
    skip: 3,
    expect: () => [
      isA<ChallengeDetailState>().having(
        (s) => s.effect,
        'effect',
        const ChallengeDetailEffect.failure(
          AppError.business('MILESTONE_LOCKED'),
        ),
      ),
      isA<ChallengeDetailState>().having((s) => s.effect, 'effect', isNull),
    ],
  );

  blocTest<ChallengeDetailBloc, ChallengeDetailState>(
    'registrar progreso recarga el historial',
    setUp: () =>
        when(() => record('c1', milestoneId: 'm1', amount: 25)).thenAnswer(
          (_) async => Success(
            ChallengeOutcome(
              challenge: challenge,
              xpDelta: 0,
              challengeCompleted: false,
            ),
          ),
        ),
    build: build,
    seed: () => ready,
    act: (b) => b.add(
      const ChallengeDetailEvent.progressRecorded(
        milestoneId: 'm1',
        amount: 25,
      ),
    ),
    expect: () => [
      ready.copyWith(busy: true),
      ready,
      ready.copyWith(
        effect: const ChallengeDetailEffect.outcome(
          xpDelta: 0,
          challengeCompleted: false,
          progressRecorded: true,
        ),
      ),
      ready,
      ready.copyWith(history: [entry]),
    ],
    verify: (_) => verifyNever(() => account()),
  );

  blocTest<ChallengeDetailBloc, ChallengeDetailState>(
    'borrar avisa de la XP restada y refresca la cuenta',
    setUp: () =>
        when(() => delete('c1')).thenAnswer((_) async => const Success(unit)),
    build: build,
    seed: () => ChallengeDetailState(
      status: ChallengeDetailStatus.ready,
      challenge: challenge.copyWith(
        milestones: [ChallengesFixtures.milestone('m1', xpAwarded: 40)],
      ),
    ),
    act: (b) => b.add(const ChallengeDetailEvent.deleteRequested()),
    skip: 2,
    expect: () => [
      isA<ChallengeDetailState>().having(
        (s) => s.effect,
        'effect',
        const ChallengeDetailEffect.deleted(
          xpLost: 40,
          account: ChallengesFixtures.account,
        ),
      ),
      isA<ChallengeDetailState>().having((s) => s.effect, 'effect', isNull),
    ],
  );

  blocTest<ChallengeDetailBloc, ChallengeDetailState>(
    'clonar un reto ajeno emite el id de la copia',
    setUp: () => when(() => clone('c1')).thenAnswer(
      (_) async => Success(ChallengesFixtures.challenge(id: 'copy')),
    ),
    build: build,
    seed: () => ChallengeDetailState(
      status: ChallengeDetailStatus.ready,
      challenge: ChallengesFixtures.challenge(owned: false),
    ),
    act: (b) => b.add(const ChallengeDetailEvent.cloneRequested()),
    skip: 2,
    expect: () => [
      isA<ChallengeDetailState>().having(
        (s) => s.effect,
        'effect',
        const ChallengeDetailEffect.cloned('copy'),
      ),
      isA<ChallengeDetailState>().having((s) => s.effect, 'effect', isNull),
    ],
  );

  blocTest<ChallengeDetailBloc, ChallengeDetailState>(
    'cambiar la visibilidad guarda y avisa',
    setUp: () => when(() => update('c1', any())).thenAnswer(
      (_) async => Success(challenge.copyWith(visibility: Visibility.public)),
    ),
    build: build,
    seed: () => ready,
    act: (b) =>
        b.add(const ChallengeDetailEvent.visibilityChanged(Visibility.public)),
    skip: 1,
    expect: () => [
      isA<ChallengeDetailState>().having(
        (s) => s.challenge!.visibility,
        'visibility',
        Visibility.public,
      ),
      isA<ChallengeDetailState>().having(
        (s) => s.effect,
        'effect',
        const ChallengeDetailEffect.saved(),
      ),
      isA<ChallengeDetailState>().having((s) => s.effect, 'effect', isNull),
    ],
    verify: (_) => verify(
      () => update('c1', const ChallengeChanges(visibility: Visibility.public)),
    ).called(1),
  );

  blocTest<ChallengeDetailBloc, ChallengeDetailState>(
    'reordenar envía el nuevo orden',
    setUp: () => when(
      () => reorder('c1', ['m2', 'm1']),
    ).thenAnswer((_) async => Success(challenge)),
    build: build,
    seed: () => ready,
    act: (b) =>
        b.add(const ChallengeDetailEvent.milestonesReordered(['m2', 'm1'])),
    verify: (_) => verify(() => reorder('c1', ['m2', 'm1'])).called(1),
  );

  blocTest<ChallengeDetailBloc, ChallengeDetailState>(
    'pedir un archivo emite su URL firmada',
    setUp: () => when(
      () => fileUrl('f1'),
    ).thenAnswer((_) async => const Success('https://r2/f1')),
    build: build,
    seed: () => ready,
    act: (b) => b.add(const ChallengeDetailEvent.fileRequested('f1')),
    expect: () => [
      ready.copyWith(
        effect: const ChallengeDetailEffect.openUrl('https://r2/f1'),
      ),
      ready,
    ],
  );
}
