import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/ai_document_type.dart';
import 'package:synaptixfit/domain/enums/mastery_state.dart';
import 'package:synaptixfit/domain/enums/artifact_kind.dart';
import 'package:synaptixfit/domain/enums/question_type.dart';
import 'package:synaptixfit/domain/enums/study_source_type.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/study_artifact.dart';
import 'package:synaptixfit/domain/models/academic/subject_file.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/academic/note_draft.dart';
import 'package:synaptixfit/domain/use_cases/academic/create_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/discard_note_draft_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/load_note_draft_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/save_note_draft_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/upload_subject_file_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/generate_study_artifact_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/generate_study_document_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_notes_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/abandon_study_material_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_review_history_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_review_preview_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_study_material_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subject_files_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/load_or_generate_study_document_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/review_study_material_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/save_artifact_as_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/save_artifact_as_quiz_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/update_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/models/academic/study_material.dart';
import 'package:synaptixfit/presentation/screens/academic/ai_document/bloc/ai_document_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/generation_center/bloc/generation_center_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/material_review/bloc/material_review_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/note_editor/bloc/note_editor_bloc.dart';

import 'academic_fixtures.dart';

class _GetNote extends Mock implements GetNoteUseCaseContract {}

class _GetSubjects extends Mock implements GetSubjectsUseCaseContract {}

class _CreateNote extends Mock implements CreateNoteUseCaseContract {}

class _UpdateNote extends Mock implements UpdateNoteUseCaseContract {}

class _LoadDraft extends Mock implements LoadNoteDraftUseCaseContract {}

class _SaveDraft extends Mock implements SaveNoteDraftUseCaseContract {}

class _DiscardDraft extends Mock implements DiscardNoteDraftUseCaseContract {}

class _Upload extends Mock implements UploadSubjectFileUseCaseContract {}

class _LoadOrGenerate extends Mock
    implements LoadOrGenerateStudyDocumentUseCaseContract {}

class _Generate extends Mock implements GenerateStudyDocumentUseCaseContract {}

class _GetNotes extends Mock implements GetNotesUseCaseContract {}

class _GetFiles extends Mock implements GetSubjectFilesUseCaseContract {}

class _GenerateArtifact extends Mock
    implements GenerateStudyArtifactUseCaseContract {}

class _SaveNote extends Mock implements SaveArtifactAsNoteUseCaseContract {}

class _SaveQuiz extends Mock implements SaveArtifactAsQuizUseCaseContract {}

class _GetMaterial extends Mock implements GetStudyMaterialUseCaseContract {}

class _GetPreview extends Mock implements GetReviewPreviewUseCaseContract {}

class _GetHistory extends Mock implements GetReviewHistoryUseCaseContract {}

class _Review extends Mock implements ReviewStudyMaterialUseCaseContract {}

class _GetAccount extends Mock implements GetAccountUseCaseContract {}

class _AbandonMaterial extends Mock
    implements AbandonStudyMaterialUseCaseContract {}

void main() {
  setUpAll(() {
    registerFallbackValue(Visibility.private);
    registerFallbackValue(ArtifactKind.summary);
    registerFallbackValue(<StudySourceRef>[]);
    registerFallbackValue(<QuestionDraft>[]);
  });

  group('NoteEditorBloc', () {
    late _GetNote getNote;
    late _GetSubjects getSubjects;
    late _CreateNote createNote;
    late _UpdateNote updateNote;
    late _LoadDraft loadDraft;
    late _SaveDraft saveDraft;
    late _DiscardDraft discardDraft;

    final draft = NoteDraft(
      accountId: 'u1',
      title: 'Límites',
      content: 'Lo que llevaba escrito',
      visibility: Visibility.private,
      quickNote: true,
      savedAt: DateTime(2026, 11, 1, 10),
    );

    setUp(() {
      registerFallbackValue(draft);
      loadDraft = _LoadDraft();
      saveDraft = _SaveDraft();
      discardDraft = _DiscardDraft();
      when(
        () => discardDraft(
          accountId: any(named: 'accountId'),
          noteId: any(named: 'noteId'),
        ),
      ).thenAnswer((_) async => const Success(unit));
      when(() => saveDraft(any())).thenAnswer((_) async => const Success(unit));
      getNote = _GetNote();
      getSubjects = _GetSubjects();
      createNote = _CreateNote();
      updateNote = _UpdateNote();
      when(
        () => getSubjects(archived: false),
      ).thenAnswer((_) async => const Success([subject]));
    });

    NoteEditorBloc build() => NoteEditorBloc(
      getNote: getNote,
      getSubjects: getSubjects,
      createNote: createNote,
      updateNote: updateNote,
      loadDraft: loadDraft,
      saveDraft: saveDraft,
      discardDraft: discardDraft,
      now: () => DateTime(2026, 11, 1, 10),
    );

    blocTest<NoteEditorBloc, NoteEditorState>(
      'ofrece recuperar el borrador que quedó sin guardar',
      setUp: () => when(
        () => loadDraft(accountId: 'u1'),
      ).thenAnswer((_) async => Success(draft)),
      build: build,
      act: (bloc) => bloc.add(const NoteEditorEvent.started(accountId: 'u1')),
      skip: 1,
      expect: () => [
        NoteEditorState(
          loading: false,
          subjects: const [subject],
          recoverableDraft: draft,
        ),
      ],
    );

    blocTest<NoteEditorBloc, NoteEditorState>(
      'guarda el borrador mientras se escribe y lo borra al descartarlo',
      setUp: () => when(
        () => loadDraft(accountId: 'u1'),
      ).thenAnswer((_) async => const Success(null)),
      build: build,
      act: (bloc) async {
        bloc.add(const NoteEditorEvent.started(accountId: 'u1'));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(
            const NoteEditorEvent.draftChanged(
              title: 'Límites',
              content: 'Lo que llevaba escrito',
              visibility: Visibility.private,
              quickNote: true,
            ),
          )
          ..add(const NoteEditorEvent.draftDiscarded());
      },
      verify: (_) {
        final saved =
            verify(() => saveDraft(captureAny())).captured.single as NoteDraft;
        expect(saved.accountId, 'u1');
        expect(saved.content, 'Lo que llevaba escrito');
        verify(() => discardDraft(accountId: 'u1')).called(1);
      },
    );

    blocTest<NoteEditorBloc, NoteEditorState>(
      'carga el apunte a editar',
      setUp: () => when(
        () => getNote('n1'),
      ).thenAnswer((_) async => const Success(note)),
      build: build,
      act: (bloc) => bloc.add(const NoteEditorEvent.started(noteId: 'n1')),
      expect: () => const [
        NoteEditorState(),
        NoteEditorState(
          loading: false,
          note: note,
          initialSubjectId: 's1',
          subjects: [subject],
        ),
      ],
    );

    blocTest<NoteEditorBloc, NoteEditorState>(
      'abre con la visibilidad rebajada a la del perfil y la recalcula si '
      'cambia la privacidad',
      setUp: () => when(() => getNote('n1')).thenAnswer(
        (_) async => Success(note.copyWith(visibility: Visibility.public)),
      ),
      build: build,
      act: (bloc) async {
        bloc.add(
          const NoteEditorEvent.started(
            noteId: 'n1',
            profilePrivacy: Visibility.friends,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const NoteEditorEvent.profilePrivacyChanged(Visibility.public),
        );
      },
      verify: (bloc) {
        expect(bloc.state.profilePrivacy, Visibility.public);
        expect(bloc.state.allowed(Visibility.public), Visibility.public);
      },
      expect: () => [
        const NoteEditorState(profilePrivacy: Visibility.friends),
        isA<NoteEditorState>().having(
          (s) => s.initialVisibility,
          'initialVisibility',
          Visibility.friends,
        ),
        isA<NoteEditorState>().having(
          (s) => s.profilePrivacy,
          'profilePrivacy',
          Visibility.public,
        ),
      ],
    );

    test(
      'Visibility.isAllowedBy no permite pasar de la privacidad del perfil',
      () {
        expect(Visibility.public.isAllowedBy(Visibility.friends), isFalse);
        expect(Visibility.friends.isAllowedBy(Visibility.friends), isTrue);
        expect(Visibility.private.isAllowedBy(Visibility.private), isTrue);
      },
    );

    blocTest<NoteEditorBloc, NoteEditorState>(
      'crea un apunte nuevo',
      setUp: () => when(
        () => createNote(
          subjectId: 's1',
          title: 'Límites',
          content: '# Límites',
          visibility: Visibility.private,
          quickNote: false,
        ),
      ).thenAnswer((_) async => const Success(note)),
      build: build,
      seed: () => const NoteEditorState(loading: false),
      act: (bloc) => bloc.add(
        const NoteEditorEvent.submitted(
          title: 'Límites',
          content: '# Límites',
          visibility: Visibility.private,
          quickNote: false,
          subjectId: 's1',
        ),
      ),
      expect: () => const [
        NoteEditorState(loading: false, saving: true),
        NoteEditorState(loading: false, note: note, savedNoteId: 'n1'),
      ],
    );

    blocTest<NoteEditorBloc, NoteEditorState>(
      'quitar la asignatura al editar envía detachSubject',
      setUp: () => when(
        () => updateNote(
          'n1',
          title: any(named: 'title'),
          content: any(named: 'content'),
          visibility: any(named: 'visibility'),
          quickNote: any(named: 'quickNote'),
          subjectId: any(named: 'subjectId'),
          detachSubject: any(named: 'detachSubject'),
        ),
      ).thenAnswer((_) async => const Success(note)),
      build: build,
      seed: () => const NoteEditorState(loading: false, note: note),
      act: (bloc) => bloc.add(
        const NoteEditorEvent.submitted(
          title: 'Límites',
          content: '',
          visibility: Visibility.public,
          quickNote: true,
        ),
      ),
      verify: (_) => verify(
        () => updateNote(
          'n1',
          title: 'Límites',
          content: '',
          visibility: Visibility.public,
          quickNote: true,
          subjectId: null,
          detachSubject: true,
        ),
      ).called(1),
    );
  });

  group('AiDocumentBloc', () {
    late _LoadOrGenerate loadOrGenerate;
    late _Generate generate;

    setUp(() {
      loadOrGenerate = _LoadOrGenerate();
      generate = _Generate();
    });

    blocTest<AiDocumentBloc, AiDocumentState>(
      'carga o genera y después regenera',
      setUp: () {
        when(
          () => loadOrGenerate(
            StudySourceType.note,
            'n1',
            AiDocumentType.summary,
          ),
        ).thenAnswer((_) async => const Success(summaryDoc));
        when(
          () => generate(StudySourceType.note, 'n1', AiDocumentType.summary),
        ).thenAnswer(
          (_) async => const Failure(AppError.business('AI_UNAVAILABLE')),
        );
      },
      build: () =>
          AiDocumentBloc(loadOrGenerate: loadOrGenerate, generate: generate),
      act: (bloc) async {
        bloc.add(
          const AiDocumentEvent.started(
            sourceType: StudySourceType.note,
            sourceId: 'n1',
            type: AiDocumentType.summary,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AiDocumentEvent.regenerated());
      },
      expect: () => const [
        AiDocumentState(sourceId: 'n1'),
        AiDocumentState(sourceId: 'n1', loading: false, document: summaryDoc),
        AiDocumentState(
          sourceId: 'n1',
          loading: false,
          document: summaryDoc,
          regenerating: true,
        ),
        AiDocumentState(
          sourceId: 'n1',
          loading: false,
          document: summaryDoc,
          actionError: AppError.business('AI_UNAVAILABLE'),
        ),
      ],
    );
  });

  group('GenerationCenterBloc', () {
    late _GetSubjects getSubjects;
    late _GetNotes getNotes;
    late _GetFiles getFiles;
    late _GenerateArtifact generateArtifact;
    late _SaveNote saveNote;
    late _SaveQuiz saveQuiz;
    const source = StudySourceRef(type: StudySourceType.note, id: 'n1');
    late _Upload upload;

    setUp(() {
      upload = _Upload();
      getSubjects = _GetSubjects();
      getNotes = _GetNotes();
      getFiles = _GetFiles();
      generateArtifact = _GenerateArtifact();
      saveNote = _SaveNote();
      saveQuiz = _SaveQuiz();
      when(
        () => getSubjects(archived: false),
      ).thenAnswer((_) async => const Success([subject]));
      when(
        () => getNotes(subjectId: 's1'),
      ).thenAnswer((_) async => const Success([note]));
      when(() => getFiles('s1')).thenAnswer((_) async => const Success([file]));
    });

    GenerationCenterBloc build() => GenerationCenterBloc(
      getSubjects: getSubjects,
      getNotes: getNotes,
      getFiles: getFiles,
      generate: generateArtifact,
      saveAsNote: saveNote,
      saveAsQuiz: saveQuiz,
      uploadFile: upload,
    );

    final payload = FileUploadPayload(
      fileName: 'tema1.pdf',
      mimeType: 'application/pdf',
      bytes: Uint8List(1),
    );

    blocTest<GenerationCenterBloc, GenerationCenterState>(
      '«Subir archivo» lo sube a la asignatura elegida y recarga las fuentes',
      setUp: () {
        registerFallbackValue(payload);
        when(
          () => upload('s1', any()),
        ).thenAnswer((_) async => const Success(file));
      },
      build: build,
      seed: () => const GenerationCenterState(loading: false, subjectId: 's1'),
      act: (bloc) =>
          bloc.add(GenerationCenterEvent.fileUploadRequested(payload)),
      verify: (bloc) {
        expect(bloc.state.uploadOutcome, FileUploadOutcome.readable);
        expect(bloc.state.files, [file]);
        verify(() => getFiles('s1')).called(1);
      },
    );

    blocTest<GenerationCenterBloc, GenerationCenterState>(
      'si la IA no puede leer el archivo, lo avisa (no sale entre las fuentes)',
      setUp: () {
        registerFallbackValue(payload);
        when(
          () => upload('s1', any()),
        ).thenAnswer((_) async => Success(file.copyWith(aiReadable: false)));
      },
      build: build,
      seed: () => const GenerationCenterState(loading: false, subjectId: 's1'),
      act: (bloc) =>
          bloc.add(GenerationCenterEvent.fileUploadRequested(payload)),
      verify: (bloc) =>
          expect(bloc.state.uploadOutcome, FileUploadOutcome.unreadable),
    );

    blocTest<GenerationCenterBloc, GenerationCenterState>(
      'con una sola asignatura carga sus fuentes',
      build: build,
      act: (bloc) => bloc.add(const GenerationCenterEvent.started()),
      verify: (bloc) {
        expect(bloc.state.subjectId, 's1');
        expect(bloc.state.notes, [note]);
        expect(bloc.state.files, [file]);
      },
    );

    blocTest<GenerationCenterBloc, GenerationCenterState>(
      'genera flashcards y las guarda como preguntas de respuesta corta',
      setUp: () {
        when(
          () => generateArtifact(ArtifactKind.flashcards, [source]),
        ).thenAnswer((_) async => const Success(artifact));
        when(
          () => saveQuiz(
            subjectId: 's1',
            title: 'Tarjetas',
            questions: any(named: 'questions'),
          ),
        ).thenAnswer(
          (_) async => const Success(
            SavedQuiz(
              noteId: 'n2',
              materialId: 'm2',
              questionBankId: 'b2',
              questionCount: 1,
            ),
          ),
        );
      },
      build: build,
      seed: () => const GenerationCenterState(
        loading: false,
        subjects: [subject],
        subjectId: 's1',
        notes: [note],
      ),
      act: (bloc) async {
        bloc
          ..add(
            const GenerationCenterEvent.kindSelected(ArtifactKind.flashcards),
          )
          ..add(const GenerationCenterEvent.sourceToggled(source))
          ..add(const GenerationCenterEvent.generateRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GenerationCenterEvent.saveRequested());
      },
      verify: (bloc) {
        expect(bloc.state.savedMaterialId, 'm2');
        verify(
          () => saveQuiz(
            subjectId: 's1',
            title: 'Tarjetas',
            questions: const [
              QuestionDraft(
                type: QuestionType.fillInBlank,
                statement: 'P',
                correctAnswer: 'R',
              ),
            ],
          ),
        ).called(1);
      },
    );

    blocTest<GenerationCenterBloc, GenerationCenterState>(
      'descartar borra el resultado efímero',
      build: build,
      seed: () =>
          const GenerationCenterState(loading: false, artifact: artifact),
      act: (bloc) => bloc.add(const GenerationCenterEvent.discarded()),
      expect: () => const [GenerationCenterState(loading: false)],
    );
  });

  group('MaterialReviewBloc', () {
    late _GetMaterial getMaterial;
    late _GetPreview getPreview;
    late _GetHistory getHistory;
    late _Review review;
    late _GetAccount getAccount;
    late _AbandonMaterial abandonMaterial;
    final reviewed = material.copyWith(intervalDays: 6);

    setUp(() {
      getMaterial = _GetMaterial();
      getPreview = _GetPreview();
      getHistory = _GetHistory();
      review = _Review();
      getAccount = _GetAccount();
      abandonMaterial = _AbandonMaterial();
      when(
        () => getMaterial('m1'),
      ).thenAnswer((_) async => const Success(material));
      when(
        () => getPreview('m1'),
      ).thenAnswer((_) async => const Success(preview));
      when(() => getHistory('m1')).thenAnswer((_) async => const Success([]));
      when(() => getAccount()).thenAnswer((_) async => const Success(account));
    });

    MaterialReviewBloc build() => MaterialReviewBloc(
      getMaterial: getMaterial,
      getPreview: getPreview,
      getHistory: getHistory,
      review: review,
      getAccount: getAccount,
      abandon: abandonMaterial,
    );

    blocTest<MaterialReviewBloc, MaterialReviewState>(
      'carga el material con los intervalos de cada nivel',
      build: build,
      act: (bloc) => bloc.add(const MaterialReviewEvent.started('m1')),
      expect: () => const [
        MaterialReviewState(materialId: 'm1'),
        MaterialReviewState(
          materialId: 'm1',
          loading: false,
          material: material,
          preview: preview,
        ),
      ],
    );

    blocTest<MaterialReviewBloc, MaterialReviewState>(
      'sin XP registra el repaso sin refrescar la cuenta',
      setUp: () => when(
        () => review('m1', 5),
      ).thenAnswer((_) async => Success(ReviewOutcome(material: reviewed))),
      build: build,
      seed: () => const MaterialReviewState(
        materialId: 'm1',
        loading: false,
        material: material,
        preview: preview,
      ),
      act: (bloc) => bloc.add(const MaterialReviewEvent.qualitySubmitted(5)),
      skip: 1,
      expect: () => [
        MaterialReviewState(
          materialId: 'm1',
          loading: false,
          material: reviewed,
          preview: preview,
          outcome: ReviewOutcome(material: reviewed),
        ),
      ],
      verify: (_) => verifyNever(() => getAccount()),
    );

    blocTest<MaterialReviewBloc, MaterialReviewState>(
      'con XP registra el repaso y refresca la cuenta',
      setUp: () => when(() => review('m1', 5)).thenAnswer(
        (_) async => Success(ReviewOutcome(material: reviewed, xpAwarded: 5)),
      ),
      build: build,
      seed: () => const MaterialReviewState(
        materialId: 'm1',
        loading: false,
        material: material,
        preview: preview,
      ),
      act: (bloc) => bloc.add(const MaterialReviewEvent.qualitySubmitted(5)),
      expect: () => [
        const MaterialReviewState(
          materialId: 'm1',
          loading: false,
          material: material,
          preview: preview,
          submitting: true,
        ),
        MaterialReviewState(
          materialId: 'm1',
          loading: false,
          material: reviewed,
          preview: preview,
          outcome: ReviewOutcome(material: reviewed, xpAwarded: 5),
        ),
        MaterialReviewState(
          materialId: 'm1',
          loading: false,
          material: reviewed,
          preview: preview,
          outcome: ReviewOutcome(material: reviewed, xpAwarded: 5),
          updatedAccount: account,
        ),
      ],
    );

    blocTest<MaterialReviewBloc, MaterialReviewState>(
      'sin repasar no se puede valorar; recordarlo sin mirar lo desbloquea',
      build: build,
      act: (bloc) async {
        bloc.add(const MaterialReviewEvent.started('m1'));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.reviewed, isFalse);
        bloc
          ..add(const MaterialReviewEvent.prepared())
          ..add(const MaterialReviewEvent.qualitySelected(4));
      },
      skip: 2,
      expect: () => const [
        MaterialReviewState(
          materialId: 'm1',
          loading: false,
          material: material,
          preview: preview,
          reviewed: true,
        ),
        MaterialReviewState(
          materialId: 'm1',
          loading: false,
          material: material,
          preview: preview,
          reviewed: true,
          selectedQuality: 4,
        ),
      ],
    );

    blocTest<MaterialReviewBloc, MaterialReviewState>(
      'al volver de practicar propone la nota con los aciertos',
      setUp: () => when(() => getPreview('m1')).thenAnswer(
        (_) async => Success(
          preview.copyWith(
            practice: const PracticeScore(
              correct: 7,
              answered: 10,
              suggestedQuality: 3,
            ),
          ),
        ),
      ),
      build: build,
      seed: () => const MaterialReviewState(
        materialId: 'm1',
        loading: false,
        material: material,
        preview: preview,
      ),
      act: (bloc) => bloc.add(const MaterialReviewEvent.practiceReturned()),
      verify: (bloc) {
        expect(bloc.state.reviewed, isTrue);
        expect(bloc.state.selectedQuality, 3);
        expect(bloc.state.preview?.practice?.correct, 7);
      },
    );

    test('tras un fallo todas las opciones dan el mismo intervalo (SM-2)', () {
      const sameDay = ReviewPreview(
        loadToday: 0,
        maxDailyLoad: 1,
        fatigueCoefficient: 1,
        options: [
          ReviewOption(
            quality: 2,
            adjustedQuality: 2,
            intervalDays: 1,
            resultingState: MasteryState.inProgress,
          ),
          ReviewOption(
            quality: 5,
            adjustedQuality: 5,
            intervalDays: 1,
            resultingState: MasteryState.inProgress,
          ),
        ],
      );
      expect(sameDay.sameIntervalForAll, isTrue);
      expect(preview.sameIntervalForAll, isFalse);
    });

    blocTest<MaterialReviewBloc, MaterialReviewState>(
      'quitar del repaso archiva el material y marca la pantalla para cerrarse',
      setUp: () => when(
        () => abandonMaterial('m1'),
      ).thenAnswer((_) async => const Success(unit)),
      build: build,
      seed: () => const MaterialReviewState(
        materialId: 'm1',
        loading: false,
        material: material,
      ),
      act: (bloc) => bloc.add(const MaterialReviewEvent.removeRequested()),
      expect: () => const [
        MaterialReviewState(
          materialId: 'm1',
          loading: false,
          material: material,
          removing: true,
        ),
        MaterialReviewState(
          materialId: 'm1',
          loading: false,
          material: material,
          removed: true,
        ),
      ],
    );
  });
}
