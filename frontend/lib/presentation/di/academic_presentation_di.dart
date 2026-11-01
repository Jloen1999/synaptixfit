import 'package:get_it/get_it.dart';

import '../screens/academic/academic_home/bloc/academic_home_bloc.dart';
import '../screens/academic/ai_document/bloc/ai_document_bloc.dart';
import '../screens/academic/file_viewer/bloc/file_viewer_bloc.dart';
import '../screens/academic/flashcards/bloc/flashcards_bloc.dart';
import '../screens/academic/free_practice/bloc/free_practice_bloc.dart';
import '../screens/academic/generation_center/bloc/generation_center_bloc.dart';
import '../screens/academic/material_review/bloc/material_review_bloc.dart';
import '../screens/academic/mock_exam/bloc/mock_exam_bloc.dart';
import '../screens/academic/note_editor/bloc/note_editor_bloc.dart';
import '../screens/academic/note_viewer/bloc/note_viewer_bloc.dart';
import '../screens/academic/practice_hub/bloc/practice_hub_bloc.dart';
import '../screens/academic/shared_note_detail/bloc/shared_note_detail_bloc.dart';
import '../screens/academic/shared_notes/bloc/shared_notes_bloc.dart';
import '../screens/academic/subject_detail/bloc/subject_detail_bloc.dart';
import '../screens/academic/subject_detail/bloc/subject_progress_bloc.dart';
import '../screens/academic/subject_detail/bloc/subject_syllabus_bloc.dart';
import '../screens/academic/subject_form/bloc/subject_form_bloc.dart';
import '../screens/academic/teaching_guide_import/bloc/teaching_guide_import_bloc.dart';
import '../screens/academic/test_results/bloc/test_results_bloc.dart';

/// Blocs del módulo academic.
void registerAcademicPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => AcademicHomeBloc(
        getSubjects: getIt(),
        getDue: getIt(),
        watchChanges: getIt(),
      ),
    )
    ..registerFactory(
      () => SubjectFormBloc(
        getSubject: getIt(),
        getSemester: getIt(),
        createSubject: getIt(),
        updateSubject: getIt(),
        assignSemester: getIt(),
        clearSemester: getIt(),
      ),
    )
    ..registerFactory(
      () => SubjectDetailBloc(
        getSubject: getIt(),
        getSemester: getIt(),
        setArchived: getIt(),
        deleteSubject: getIt(),
      ),
    )
    ..registerFactory(
      () => SubjectProgressBloc(
        getGuide: getIt(),
        setMode: getIt(),
        setTopic: getIt(),
        setGrade: getIt(),
        getRetention: getIt(),
        getTimeline: getIt(),
        getMaterials: getIt(),
      ),
    )
    ..registerFactory(
      () => TeachingGuideImportBloc(
        start: getIt(),
        await: getIt(),
        retry: getIt(),
        apply: getIt(),
        discard: getIt(),
      ),
    )
    ..registerFactory(
      () => SubjectSyllabusBloc(
        watchChanges: getIt(),
        getNotes: getIt(),
        getFiles: getIt(),
        getAvailability: getIt(),
        uploadFile: getIt(),
        deleteFile: getIt(),
        deleteNote: getIt(),
        registerMaterial: getIt(),
      ),
    )
    ..registerFactory(
      () => NoteEditorBloc(
        getNote: getIt(),
        getSubjects: getIt(),
        createNote: getIt(),
        updateNote: getIt(),
      ),
    )
    ..registerFactory(
      () => NoteViewerBloc(
        getNote: getIt(),
        getAvailability: getIt(),
        deleteNote: getIt(),
        registerMaterial: getIt(),
      ),
    )
    ..registerFactory(() => SharedNotesBloc(getShared: getIt()))
    ..registerFactory(
      () => SharedNoteDetailBloc(getNote: getIt(), copyNote: getIt()),
    )
    ..registerFactory(
      () => FileViewerBloc(
        getContent: getIt(),
        getAvailability: getIt(),
        deleteFile: getIt(),
        registerMaterial: getIt(),
      ),
    )
    ..registerFactory(
      () => AiDocumentBloc(loadOrGenerate: getIt(), generate: getIt()),
    )
    ..registerFactory(
      () => GenerationCenterBloc(
        getSubjects: getIt(),
        getNotes: getIt(),
        getFiles: getIt(),
        generate: getIt(),
        saveAsNote: getIt(),
        saveAsQuiz: getIt(),
      ),
    )
    ..registerFactory(
      () => MaterialReviewBloc(
        getMaterial: getIt(),
        getPreview: getIt(),
        getHistory: getIt(),
        review: getIt(),
        getAccount: getIt(),
        abandon: getIt(),
      ),
    )
    ..registerFactory(
      () => PracticeHubBloc(
        getMaterial: getIt(),
        getBank: getIt(),
        generateBank: getIt(),
        getActiveSession: getIt(),
        getSessions: getIt(),
      ),
    )
    ..registerFactory(
      () => FreePracticeBloc(
        getBank: getIt(),
        answer: getIt(),
        complete: getIt(),
        getAccount: getIt(),
      ),
    )
    ..registerFactory(
      () => FlashcardsBloc(
        getBank: getIt(),
        getMaterial: getIt(),
        reviewFlashcards: getIt(),
        exportAnki: getIt(),
        getAccount: getIt(),
      ),
    )
    ..registerFactory(
      () => MockExamBloc(
        getActive: getIt(),
        start: getIt(),
        answer: getIt(),
        complete: getIt(),
        abandon: getIt(),
        getAccount: getIt(),
      ),
    )
    ..registerFactory(() => TestResultsBloc(getSession: getIt()));
}
