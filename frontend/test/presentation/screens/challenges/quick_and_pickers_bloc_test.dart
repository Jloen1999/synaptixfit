import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/challenge_difficulty.dart';
import 'package:synaptixfit/domain/enums/challenge_link_type.dart';
import 'package:synaptixfit/domain/enums/challenge_type.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/challenges/challenge.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_draft.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_references.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/challenges/create_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_challenge_attachments_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_challenge_link_targets_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/list_challenge_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/challenges/update_challenge_use_case.dart';
import 'package:synaptixfit/presentation/screens/challenges/attachment_picker/bloc/attachment_picker_bloc.dart';
import 'package:synaptixfit/presentation/screens/challenges/link_picker/bloc/link_picker_bloc.dart';
import 'package:synaptixfit/presentation/screens/challenges/quick_challenge/bloc/quick_challenge_bloc.dart';

import 'challenges_fixtures.dart';

class _Subjects extends Mock implements ListChallengeSubjectsUseCaseContract {}

class _Create extends Mock implements CreateChallengeUseCaseContract {}

class _Update extends Mock implements UpdateChallengeUseCaseContract {}

class _Attachments extends Mock
    implements ListChallengeAttachmentsUseCaseContract {}

class _Targets extends Mock
    implements ListChallengeLinkTargetsUseCaseContract {}

void main() {
  const algebra = ChallengeSubjectOption(id: 's1', name: 'Álgebra');
  late _Subjects subjects;

  setUpAll(() {
    registerFallbackValue(ChallengeDraft(title: 'x', endAt: DateTime(2026)));
    registerFallbackValue(const ChallengeChanges());
  });

  setUp(() {
    subjects = _Subjects();
    when(() => subjects()).thenAnswer((_) async => const Success([algebra]));
  });

  group('QuickChallengeBloc', () {
    late _Create create;
    late _Update update;
    final end = DateTime(2026, 10, 25, 23, 59);

    setUp(() {
      create = _Create();
      update = _Update();
    });

    QuickChallengeBloc build() => QuickChallengeBloc(
      listSubjects: subjects,
      createChallenge: create,
      updateChallenge: update,
    );

    blocTest<QuickChallengeBloc, QuickChallengeState>(
      'carga las asignaturas',
      build: build,
      act: (b) => b.add(const QuickChallengeEvent.started()),
      expect: () => [
        const QuickChallengeState(
          status: QuickChallengeStatus.ready,
          subjects: [algebra],
        ),
      ],
    );

    blocTest<QuickChallengeBloc, QuickChallengeState>(
      'crea un reto sin tareas',
      setUp: () => when(
        () => create(any()),
      ).thenAnswer((_) async => Success(ChallengesFixtures.challenge())),
      build: build,
      seed: () => const QuickChallengeState(status: QuickChallengeStatus.ready),
      act: (b) => b.add(
        QuickChallengeEvent.submitted(
          title: 'Correr 5 km',
          type: ChallengeType.fitness,
          difficulty: ChallengeDifficulty.high,
          endAt: end,
        ),
      ),
      expect: () => [
        const QuickChallengeState(status: QuickChallengeStatus.saving),
        QuickChallengeState(
          status: QuickChallengeStatus.saved,
          saved: ChallengesFixtures.challenge(),
        ),
      ],
      verify: (_) => verify(
        () => create(
          ChallengeDraft(
            title: 'Correr 5 km',
            type: ChallengeType.fitness,
            difficulty: ChallengeDifficulty.high,
            endAt: end,
          ),
        ),
      ).called(1),
    );

    blocTest<QuickChallengeBloc, QuickChallengeState>(
      'al editar y quitar la asignatura envía clearSubject',
      setUp: () => when(
        () => update('c1', any()),
      ).thenAnswer((_) async => Success(ChallengesFixtures.challenge())),
      build: build,
      seed: () => const QuickChallengeState(status: QuickChallengeStatus.ready),
      act: (b) => b.add(
        QuickChallengeEvent.submitted(
          editing: ChallengesFixtures.challenge(subjectId: 's1'),
          title: 'Reto editado',
          type: ChallengeType.academic,
          difficulty: ChallengeDifficulty.low,
          endAt: end,
        ),
      ),
      verify: (_) => verify(
        () => update(
          'c1',
          ChallengeChanges(
            title: 'Reto editado',
            type: ChallengeType.academic,
            difficulty: ChallengeDifficulty.low,
            endAt: end,
            clearSubject: true,
          ),
        ),
      ).called(1),
    );

    blocTest<QuickChallengeBloc, QuickChallengeState>(
      'crea un reto de fitness con objetivo de sesiones',
      setUp: () => when(
        () => create(any()),
      ).thenAnswer((_) async => Success(ChallengesFixtures.challenge())),
      build: build,
      seed: () => const QuickChallengeState(status: QuickChallengeStatus.ready),
      act: (b) => b.add(
        QuickChallengeEvent.submitted(
          title: 'Doce entrenos',
          type: ChallengeType.fitness,
          difficulty: ChallengeDifficulty.medium,
          endAt: end,
          sessionTarget: 12,
        ),
      ),
      verify: (_) {
        final draft =
            verify(() => create(captureAny())).captured.single
                as ChallengeDraft;
        expect(draft.sessionTarget, 12);
      },
    );

    group('al editar el objetivo de sesiones', () {
      final fitness = ChallengesFixtures.challenge().copyWith(
        type: ChallengeType.fitness,
        sessionTarget: 10,
        tracksTrainingSessions: true,
      );

      void submit(
        QuickChallengeBloc b, {
        required Challenge editing,
        required ChallengeType type,
        int? target,
      }) {
        b.add(
          QuickChallengeEvent.submitted(
            editing: editing,
            title: 'Reto editado',
            type: type,
            difficulty: ChallengeDifficulty.medium,
            endAt: end,
            sessionTarget: target,
          ),
        );
      }

      ChallengeChanges captured() =>
          verify(() => update('c1', captureAny())).captured.single
              as ChallengeChanges;

      setUp(
        () => when(
          () => update('c1', any()),
        ).thenAnswer((_) async => Success(ChallengesFixtures.challenge())),
      );

      blocTest<QuickChallengeBloc, QuickChallengeState>(
        'lo cambia',
        build: build,
        act: (b) => submit(
          b,
          editing: fitness,
          type: ChallengeType.fitness,
          target: 20,
        ),
        verify: (_) {
          final changes = captured();
          expect(changes.sessionTarget, 20);
          expect(changes.clearSessionTarget, isFalse);
        },
      );

      blocTest<QuickChallengeBloc, QuickChallengeState>(
        'lo quita si se vacía el campo',
        build: build,
        act: (b) => submit(b, editing: fitness, type: ChallengeType.fitness),
        verify: (_) => expect(captured().clearSessionTarget, isTrue),
      );

      blocTest<QuickChallengeBloc, QuickChallengeState>(
        'lo quita al pasar el reto a académico',
        build: build,
        act: (b) => submit(
          b,
          editing: fitness,
          type: ChallengeType.academic,
          target: 20,
        ),
        verify: (_) {
          final changes = captured();
          expect(changes.sessionTarget, isNull);
          expect(changes.clearSessionTarget, isTrue);
        },
      );

      blocTest<QuickChallengeBloc, QuickChallengeState>(
        'con tareas lo conserva (el campo no se muestra)',
        build: build,
        act: (b) => submit(
          b,
          // Con tareas el servidor indica que no cuenta sesiones.
          editing: fitness.copyWith(
            milestoneCount: 2,
            tracksTrainingSessions: false,
          ),
          type: ChallengeType.fitness,
        ),
        verify: (_) {
          final changes = captured();
          expect(changes.sessionTarget, isNull);
          expect(changes.clearSessionTarget, isFalse);
        },
      );
    });

    blocTest<QuickChallengeBloc, QuickChallengeState>(
      'muestra el error del servidor y sigue editable',
      setUp: () => when(() => create(any())).thenAnswer(
        (_) async =>
            const Failure(AppError.business('CHALLENGE_INVALID_DATES')),
      ),
      build: build,
      seed: () => const QuickChallengeState(status: QuickChallengeStatus.ready),
      act: (b) => b.add(
        QuickChallengeEvent.submitted(
          title: 'Correr 5 km',
          type: ChallengeType.fitness,
          difficulty: ChallengeDifficulty.medium,
          endAt: end,
        ),
      ),
      expect: () => [
        const QuickChallengeState(status: QuickChallengeStatus.saving),
        const QuickChallengeState(
          status: QuickChallengeStatus.ready,
          error: AppError.business('CHALLENGE_INVALID_DATES'),
        ),
      ],
    );
  });

  group('AttachmentPickerBloc', () {
    late _Attachments attachments;
    const options = ChallengeAttachmentOptions(
      notes: [ChallengeNoteOption(id: 'n1', title: 'Tema 1')],
      files: [ChallengeFileOption(id: 'f1', fileName: 'tema1.pdf')],
    );

    setUp(() {
      attachments = _Attachments();
      when(
        () => attachments(any()),
      ).thenAnswer((_) async => const Success(options));
    });

    blocTest<AttachmentPickerBloc, AttachmentPickerState>(
      'sin asignatura inicial usa la primera y carga su material',
      build: () => AttachmentPickerBloc(
        listSubjects: subjects,
        listAttachments: attachments,
      ),
      act: (b) => b.add(const AttachmentPickerEvent.started()),
      expect: () => [
        const AttachmentPickerState(),
        const AttachmentPickerState(subjects: [algebra], subjectId: 's1'),
        const AttachmentPickerState(
          status: AttachmentPickerStatus.ready,
          subjects: [algebra],
          subjectId: 's1',
          options: options,
        ),
      ],
    );

    blocTest<AttachmentPickerBloc, AttachmentPickerState>(
      'cambiar a «sin asignatura» pide los apuntes sin asignar',
      build: () => AttachmentPickerBloc(
        listSubjects: subjects,
        listAttachments: attachments,
      ),
      seed: () => const AttachmentPickerState(
        status: AttachmentPickerStatus.ready,
        subjectId: 's1',
      ),
      act: (b) => b.add(const AttachmentPickerEvent.subjectChanged(null)),
      expect: () => [
        const AttachmentPickerState(),
        const AttachmentPickerState(
          status: AttachmentPickerStatus.ready,
          options: options,
        ),
      ],
      verify: (_) => verify(() => attachments(null)).called(1),
    );
  });

  group('LinkPickerBloc', () {
    late _Targets targets;
    final option = ChallengeLinkOption(
      id: 'd1',
      type: ChallengeLinkType.exam,
      title: 'Parcial',
      at: DateTime(2026, 11, 1),
    );

    setUp(() => targets = _Targets());

    blocTest<LinkPickerBloc, LinkPickerState>(
      'carga entregas y bloques de la asignatura',
      setUp: () => when(
        () => targets(subjectId: 's1'),
      ).thenAnswer((_) async => Success([option])),
      build: () => LinkPickerBloc(listTargets: targets),
      act: (b) => b.add(const LinkPickerEvent.started(subjectId: 's1')),
      expect: () => [
        const LinkPickerState(),
        LinkPickerState(status: LinkPickerStatus.ready, options: [option]),
      ],
    );

    blocTest<LinkPickerBloc, LinkPickerState>(
      'emite failure si falla',
      setUp: () => when(
        () => targets(subjectId: any(named: 'subjectId')),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: () => LinkPickerBloc(listTargets: targets),
      act: (b) => b.add(const LinkPickerEvent.started()),
      expect: () => [
        const LinkPickerState(),
        const LinkPickerState(
          status: LinkPickerStatus.failure,
          error: AppError.network(),
        ),
      ],
    );
  });
}
