import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/artifact_kind.dart';
import 'package:synaptixfit/domain/enums/question_type.dart';
import 'package:synaptixfit/domain/enums/study_source_type.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/mock_exam_options.dart';
import 'package:synaptixfit/domain/models/academic/note_scan.dart';
import 'package:synaptixfit/domain/models/academic/study_artifact.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/abandon_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/answer_in_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/complete_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/create_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/generate_study_artifact_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_active_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_mock_exam_options_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_notes_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subject_files_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/read_note_photos_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/save_artifact_as_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/save_artifact_as_quiz_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/start_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/upload_subject_file_use_case.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/presentation/screens/academic/generation_center/bloc/generation_center_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/mock_exam/bloc/mock_exam_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/mock_exam_setup/bloc/mock_exam_setup_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/note_scan/bloc/note_scan_bloc.dart';

import 'academic_fixtures.dart';

class _GetOptions extends Mock implements GetMockExamOptionsUseCaseContract {}

class _GetSubjects extends Mock implements GetSubjectsUseCaseContract {}

class _ReadPhotos extends Mock implements ReadNotePhotosUseCaseContract {}

class _CreateNote extends Mock implements CreateNoteUseCaseContract {}

class _GetActive extends Mock implements GetActiveTestSessionUseCaseContract {}

class _Start extends Mock implements StartTestSessionUseCaseContract {}

class _Answer extends Mock implements AnswerInTestSessionUseCaseContract {}

class _Complete extends Mock implements CompleteTestSessionUseCaseContract {}

class _Abandon extends Mock implements AbandonTestSessionUseCaseContract {}

class _GetAccount extends Mock implements GetAccountUseCaseContract {}

class _GetNotes extends Mock implements GetNotesUseCaseContract {}

class _GetFiles extends Mock implements GetSubjectFilesUseCaseContract {}

class _Generate extends Mock implements GenerateStudyArtifactUseCaseContract {}

class _SaveNote extends Mock implements SaveArtifactAsNoteUseCaseContract {}

class _SaveQuiz extends Mock implements SaveArtifactAsQuizUseCaseContract {}

class _Upload extends Mock implements UploadSubjectFileUseCaseContract {}

MockExamSource _source(String id, int questions) => MockExamSource(
  materialId: id,
  title: 'Tema $id',
  originType: StudySourceType.note,
  questionCount: questions,
);

const _photo = NotePhotoUpload(
  bytes: [1, 2, 3],
  fileName: 'pagina.jpg',
  mimeType: 'image/jpeg',
);

const _photo2 = NotePhotoUpload(
  bytes: [4, 5, 6],
  fileName: 'pagina2.jpg',
  mimeType: 'image/jpeg',
);

void main() {
  group('MockExamSetupBloc', () {
    late _GetOptions getOptions;

    setUp(() => getOptions = _GetOptions());

    blocTest<MockExamSetupBloc, MockExamSetupState>(
      'entra todo hasta el máximo y el número de preguntas se ajusta a lo que hay',
      setUp: () => when(() => getOptions('s1')).thenAnswer(
        (_) async => Success(
          MockExamOptions(
            sources: [_source('a', 8), _source('b', 6), _source('c', 4)],
            maxMaterials: 2,
            suggestedQuestions: 20,
            maxQuestions: 50,
          ),
        ),
      ),
      build: () => MockExamSetupBloc(getOptions: getOptions),
      act: (bloc) async {
        bloc.add(const MockExamSetupEvent.started('s1'));
        await Future<void>.delayed(Duration.zero);
        // Con el máximo lleno, «c» no entra hasta quitar otro.
        bloc
          ..add(const MockExamSetupEvent.sourceToggled('c'))
          ..add(const MockExamSetupEvent.sourceToggled('b'))
          ..add(const MockExamSetupEvent.sourceToggled('c'));
      },
      verify: (bloc) {
        final s = bloc.state;
        expect(s.selected, {'a', 'c'});
        expect(s.available, 12);
        // 12 preguntas: se ofrecen 10 y 12, y se elige la que cabe.
        expect(s.countChoices, [10, 12]);
        expect(s.count, 10);
        expect(s.orderedSelection, ['a', 'c']);
        expect(s.canStart, isTrue);
      },
    );

    test('con pocas preguntas se ofrecen todas las que hay', () {
      final s = MockExamSetupState(
        options: MockExamOptions(
          sources: [_source('a', 7)],
          maxMaterials: 10,
          suggestedQuestions: 20,
          maxQuestions: 50,
        ),
        selected: const {'a'},
      );
      expect(s.countChoices, [7]);
      expect(s.copyWith(selected: const {}).countChoices, isEmpty);
    });

    blocTest<MockExamSetupBloc, MockExamSetupState>(
      'sin conexión muestra el error para reintentar',
      setUp: () => when(
        () => getOptions('s1'),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: () => MockExamSetupBloc(getOptions: getOptions),
      act: (bloc) => bloc.add(const MockExamSetupEvent.started('s1')),
      verify: (bloc) => expect(bloc.state.error, const AppError.network()),
    );
  });

  group('MockExamBloc con varios materiales', () {
    blocTest<MockExamBloc, MockExamState>(
      'empieza con todos los materiales y el número de preguntas elegido',
      setUp: () {},
      build: () {
        final start = _Start();
        when(
          () => start(['a', 'b', 'c'], questionCount: 20),
        ).thenAnswer((_) async => Success(session));
        return MockExamBloc(
          getActive: _GetActive(),
          start: start,
          answer: _Answer(),
          complete: _Complete(),
          abandon: _Abandon(),
          getAccount: _GetAccount(),
        );
      },
      act: (bloc) => bloc.add(
        const MockExamEvent.started(
          materialId: 'a',
          extraMaterialIds: ['b', 'c'],
          questionCount: 20,
        ),
      ),
      verify: (bloc) => expect(bloc.state.session, session),
    );
  });

  group('NoteScanBloc', () {
    late _GetSubjects getSubjects;
    late _ReadPhotos readPhotos;
    late _CreateNote createNote;

    setUp(() {
      getSubjects = _GetSubjects();
      readPhotos = _ReadPhotos();
      createNote = _CreateNote();
      when(
        () => getSubjects(archived: false),
      ).thenAnswer((_) async => const Success([subject]));
    });

    NoteScanBloc build() => NoteScanBloc(
      getSubjects: getSubjects,
      readPhotos: readPhotos,
      createNote: createNote,
    );

    blocTest<NoteScanBloc, NoteScanState>(
      'no deja pasar de 5 fotos y quitar una deja sitio',
      build: build,
      act: (bloc) => bloc
        ..add(NoteScanEvent.photosAdded(List.filled(4, _photo)))
        ..add(NoteScanEvent.photosAdded(List.filled(3, _photo)))
        ..add(const NoteScanEvent.photoRemoved(0)),
      verify: (bloc) {
        expect(bloc.state.photos, hasLength(NoteScanState.maxPhotos - 1));
        expect(bloc.state.canAddMore, isTrue);
      },
    );

    blocTest<NoteScanBloc, NoteScanState>(
      'deshacer devuelve la página a su sitio',
      build: build,
      act: (bloc) => bloc
        ..add(const NoteScanEvent.photosAdded([_photo, _photo2]))
        ..add(const NoteScanEvent.photoRemoved(0))
        ..add(const NoteScanEvent.photoRestored(0, _photo)),
      verify: (bloc) => expect(bloc.state.photos, [_photo, _photo2]),
    );

    blocTest<NoteScanBloc, NoteScanState>(
      'sin permiso de cámara lo explica, y elegir de la galería lo quita',
      build: build,
      act: (bloc) => bloc
        ..add(const NoteScanEvent.cameraUnavailable(denied: true))
        ..add(const NoteScanEvent.photosAdded([_photo])),
      expect: () => [
        isA<NoteScanState>().having(
          (s) => s.cameraProblem,
          'cámara',
          NoteScanCameraProblem.denied,
        ),
        isA<NoteScanState>()
            .having((s) => s.cameraProblem, 'cámara', isNull)
            .having((s) => s.photos, 'fotos', [_photo]),
      ],
    );

    blocTest<NoteScanBloc, NoteScanState>(
      'lee las fotos, se revisa el texto y se guarda como apunte privado',
      setUp: () {
        when(() => readPhotos([_photo, _photo])).thenAnswer(
          (_) async => const Success(
            ScannedNoteDraft(
              title: 'La célula',
              markdown: '## La célula',
              tidied: true,
              pages: 2,
            ),
          ),
        );
        when(
          () => createNote(
            subjectId: 's1',
            title: 'La célula',
            content: '## La célula corregida',
            visibility: Visibility.private,
            quickNote: false,
          ),
        ).thenAnswer((_) async => const Success(note));
      },
      build: build,
      act: (bloc) async {
        bloc
          ..add(const NoteScanEvent.started(subjectId: 's1'))
          ..add(const NoteScanEvent.photosAdded([_photo, _photo]))
          ..add(const NoteScanEvent.readRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const NoteScanEvent.saveRequested(
            title: ' La célula ',
            markdown: '## La célula corregida',
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.draft?.tidied, isTrue);
        expect(bloc.state.subjects, [subject]);
        expect(bloc.state.savedNoteId, note.id);
      },
    );

    blocTest<NoteScanBloc, NoteScanState>(
      'si no se lee nada, se queda en las fotos con el aviso',
      setUp: () => when(() => readPhotos([_photo])).thenAnswer(
        (_) async =>
            const Failure(AppError.business('NOTE_SCAN_NOTHING_FOUND')),
      ),
      build: build,
      act: (bloc) => bloc
        ..add(const NoteScanEvent.photosAdded([_photo]))
        ..add(const NoteScanEvent.readRequested()),
      verify: (bloc) {
        expect(bloc.state.draft, isNull);
        expect(bloc.state.photos, hasLength(1));
        expect(
          bloc.state.readError,
          const AppError.business('NOTE_SCAN_NOTHING_FOUND'),
        );
      },
    );
  });

  group('GenerationCenterBloc: corregir antes de guardar', () {
    late _Generate generate;

    const test = StudyArtifact(
      kind: ArtifactKind.practiceTest,
      title: 'Test',
      questions: [
        QuestionDraft(
          type: QuestionType.multipleChoice,
          statement: '¿2+2?',
          options: ['3', '5'],
          correctAnswer: '3',
        ),
        QuestionDraft(
          type: QuestionType.fillInBlank,
          statement: 'Capital de Francia',
          correctAnswer: 'París',
        ),
      ],
    );

    setUp(() => generate = _Generate());

    GenerationCenterBloc build() => GenerationCenterBloc(
      getSubjects: _GetSubjects(),
      getNotes: _GetNotes(),
      getFiles: _GetFiles(),
      generate: generate,
      saveAsNote: _SaveNote(),
      saveAsQuiz: _SaveQuiz(),
      uploadFile: _Upload(),
    );

    blocTest<GenerationCenterBloc, GenerationCenterState>(
      'corrige una pregunta, quita otra y la recupera con deshacer',
      seed: () => const GenerationCenterState(loading: false, artifact: test),
      build: build,
      act: (bloc) => bloc
        ..add(
          GenerationCenterEvent.questionEdited(
            0,
            test.questions.first.copyWith(
              options: ['4', '5'],
              correctAnswer: '4',
            ),
          ),
        )
        ..add(const GenerationCenterEvent.itemRemoved(1))
        ..add(const GenerationCenterEvent.removalUndone()),
      verify: (bloc) {
        final a = bloc.state.artifact!;
        expect(a.questions, hasLength(2));
        expect(a.questions.first.correctAnswer, '4');
        expect(bloc.state.edited, isTrue);
        expect(bloc.state.canSave, isTrue);
      },
    );

    blocTest<GenerationCenterBloc, GenerationCenterState>(
      'sin preguntas no se puede guardar; el resumen corregido sí',
      seed: () => const GenerationCenterState(loading: false, artifact: test),
      build: build,
      act: (bloc) => bloc
        ..add(const GenerationCenterEvent.itemRemoved(0))
        ..add(const GenerationCenterEvent.itemRemoved(0)),
      verify: (bloc) {
        expect(bloc.state.canSave, isFalse);
        const summary = GenerationCenterState(
          artifact: StudyArtifact(
            kind: ArtifactKind.summary,
            title: 'R',
            markdown: '  ',
          ),
        );
        expect(summary.canSave, isFalse);
      },
    );

    blocTest<GenerationCenterBloc, GenerationCenterState>(
      'corrige el texto del resumen y una tarjeta',
      seed: () =>
          const GenerationCenterState(loading: false, artifact: artifact),
      build: build,
      act: (bloc) => bloc
        ..add(const GenerationCenterEvent.summaryEdited('Texto corregido'))
        ..add(
          const GenerationCenterEvent.flashcardEdited(
            0,
            Flashcard(question: 'P2', answer: 'R2'),
          ),
        ),
      verify: (bloc) {
        expect(bloc.state.artifact!.markdown, 'Texto corregido');
        expect(
          bloc.state.artifact!.flashcards.single,
          const Flashcard(question: 'P2', answer: 'R2'),
        );
      },
    );
  });
}
