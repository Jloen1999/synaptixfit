import 'package:get_it/get_it.dart';

import '../use_cases/academic/abandon_test_session_use_case.dart';
import '../use_cases/academic/get_mock_exam_options_use_case.dart';
import '../use_cases/academic/read_note_photos_use_case.dart';
import '../use_cases/academic/answer_in_test_session_use_case.dart';
import '../use_cases/academic/answer_question_use_case.dart';
import '../use_cases/academic/assign_subject_semester_use_case.dart';
import '../use_cases/academic/clear_subject_semester_use_case.dart';
import '../use_cases/academic/complete_practice_use_case.dart';
import '../use_cases/academic/complete_test_session_use_case.dart';
import '../use_cases/academic/create_note_use_case.dart';
import '../use_cases/academic/create_subject_use_case.dart';
import '../use_cases/academic/delete_note_use_case.dart';
import '../use_cases/academic/abandon_study_material_use_case.dart';
import '../use_cases/academic/delete_study_material_use_case.dart';
import '../use_cases/academic/delete_subject_file_use_case.dart';
import '../use_cases/academic/delete_subject_use_case.dart';
import '../use_cases/academic/generate_question_bank_use_case.dart';
import '../use_cases/academic/generate_study_artifact_use_case.dart';
import '../use_cases/academic/generate_study_document_use_case.dart';
import '../use_cases/academic/apply_teaching_guide_import_use_case.dart';
import '../use_cases/academic/await_teaching_guide_import_use_case.dart';
import '../use_cases/academic/discard_teaching_guide_import_use_case.dart';
import '../use_cases/academic/export_flashcards_to_anki_use_case.dart';
import '../use_cases/academic/retry_teaching_guide_import_use_case.dart';
import '../use_cases/academic/set_teaching_guide_mode_use_case.dart';
import '../use_cases/academic/start_teaching_guide_import_use_case.dart';
import '../use_cases/academic/get_active_test_session_use_case.dart';
import '../use_cases/academic/get_document_availability_use_case.dart';
import '../use_cases/academic/get_due_study_materials_use_case.dart';
import '../use_cases/academic/get_file_content_use_case.dart';
import '../use_cases/academic/get_note_use_case.dart';
import '../use_cases/academic/get_notes_use_case.dart';
import '../use_cases/academic/get_unassigned_notes_use_case.dart';
import '../use_cases/academic/load_note_draft_use_case.dart';
import '../use_cases/academic/save_note_draft_use_case.dart';
import '../use_cases/academic/discard_note_draft_use_case.dart';
import '../use_cases/academic/move_note_to_subject_use_case.dart';
import '../use_cases/academic/get_question_bank_use_case.dart';
import '../use_cases/academic/get_review_history_use_case.dart';
import '../use_cases/academic/get_review_preview_use_case.dart';
import '../use_cases/academic/copy_shared_note_use_case.dart';
import '../use_cases/academic/get_shared_note_use_case.dart';
import '../use_cases/academic/get_shared_notes_use_case.dart';
import '../use_cases/academic/get_study_material_use_case.dart';
import '../use_cases/academic/get_study_materials_use_case.dart';
import '../use_cases/academic/get_subject_files_use_case.dart';
import '../use_cases/academic/get_subject_retention_use_case.dart';
import '../use_cases/academic/get_subject_semester_use_case.dart';
import '../use_cases/academic/get_subject_timeline_use_case.dart';
import '../use_cases/academic/get_subject_use_case.dart';
import '../use_cases/academic/get_subjects_use_case.dart';
import '../use_cases/academic/get_teaching_guide_use_case.dart';
import '../use_cases/academic/get_test_session_use_case.dart';
import '../use_cases/academic/get_test_sessions_use_case.dart';
import '../use_cases/academic/load_or_generate_study_document_use_case.dart';
import '../use_cases/academic/register_study_material_use_case.dart';
import '../use_cases/academic/review_flashcards_use_case.dart';
import '../use_cases/academic/review_study_material_use_case.dart';
import '../use_cases/academic/save_artifact_as_note_use_case.dart';
import '../use_cases/academic/save_artifact_as_quiz_use_case.dart';
import '../use_cases/academic/set_assessment_grade_use_case.dart';
import '../use_cases/academic/set_subject_archived_use_case.dart';
import '../use_cases/academic/set_syllabus_topic_completed_use_case.dart';
import '../use_cases/academic/start_test_session_use_case.dart';
import '../use_cases/academic/update_note_use_case.dart';
import '../use_cases/academic/update_subject_use_case.dart';
import '../use_cases/academic/upload_subject_file_use_case.dart';

/// Casos de uso del módulo academic.
void registerAcademicDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<AbandonTestSessionUseCaseContract>(
      () => AbandonTestSessionUseCase(getIt()),
    )
    ..registerLazySingleton<AnswerInTestSessionUseCaseContract>(
      () => AnswerInTestSessionUseCase(getIt()),
    )
    ..registerLazySingleton<AnswerQuestionUseCaseContract>(
      () => AnswerQuestionUseCase(getIt()),
    )
    ..registerLazySingleton<AssignSubjectSemesterUseCaseContract>(
      () => AssignSubjectSemesterUseCase(getIt()),
    )
    ..registerLazySingleton<ClearSubjectSemesterUseCaseContract>(
      () => ClearSubjectSemesterUseCase(getIt()),
    )
    ..registerLazySingleton<CompletePracticeUseCaseContract>(
      () => CompletePracticeUseCase(getIt()),
    )
    ..registerLazySingleton<CompleteTestSessionUseCaseContract>(
      () => CompleteTestSessionUseCase(getIt()),
    )
    ..registerLazySingleton<CreateNoteUseCaseContract>(
      () => CreateNoteUseCase(getIt()),
    )
    ..registerLazySingleton<CreateSubjectUseCaseContract>(
      () => CreateSubjectUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteNoteUseCaseContract>(
      () => DeleteNoteUseCase(getIt()),
    )
    ..registerLazySingleton<AbandonStudyMaterialUseCaseContract>(
      () => AbandonStudyMaterialUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteStudyMaterialUseCaseContract>(
      () => DeleteStudyMaterialUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteSubjectFileUseCaseContract>(
      () => DeleteSubjectFileUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteSubjectUseCaseContract>(
      () => DeleteSubjectUseCase(getIt()),
    )
    ..registerLazySingleton<GenerateQuestionBankUseCaseContract>(
      () => GenerateQuestionBankUseCase(getIt()),
    )
    ..registerLazySingleton<GenerateStudyArtifactUseCaseContract>(
      () => GenerateStudyArtifactUseCase(getIt()),
    )
    ..registerLazySingleton<GenerateStudyDocumentUseCaseContract>(
      () => GenerateStudyDocumentUseCase(getIt()),
    )
    ..registerLazySingleton<SetTeachingGuideModeUseCaseContract>(
      () => SetTeachingGuideModeUseCase(getIt()),
    )
    ..registerLazySingleton<StartTeachingGuideImportUseCaseContract>(
      () => StartTeachingGuideImportUseCase(getIt()),
    )
    ..registerLazySingleton<AwaitTeachingGuideImportUseCaseContract>(
      () => AwaitTeachingGuideImportUseCase(getIt()),
    )
    ..registerLazySingleton<RetryTeachingGuideImportUseCaseContract>(
      () => RetryTeachingGuideImportUseCase(getIt()),
    )
    ..registerLazySingleton<ApplyTeachingGuideImportUseCaseContract>(
      () => ApplyTeachingGuideImportUseCase(getIt()),
    )
    ..registerLazySingleton<DiscardTeachingGuideImportUseCaseContract>(
      () => DiscardTeachingGuideImportUseCase(getIt()),
    )
    ..registerLazySingleton<GetActiveTestSessionUseCaseContract>(
      () => GetActiveTestSessionUseCase(getIt()),
    )
    ..registerLazySingleton<GetDocumentAvailabilityUseCaseContract>(
      () => GetDocumentAvailabilityUseCase(getIt()),
    )
    ..registerLazySingleton<GetDueStudyMaterialsUseCaseContract>(
      () => GetDueStudyMaterialsUseCase(getIt()),
    )
    ..registerLazySingleton<GetFileContentUseCaseContract>(
      () => GetFileContentUseCase(getIt()),
    )
    ..registerLazySingleton<GetNoteUseCaseContract>(
      () => GetNoteUseCase(getIt()),
    )
    ..registerLazySingleton<GetNotesUseCaseContract>(
      () => GetNotesUseCase(getIt()),
    )
    ..registerLazySingleton<LoadNoteDraftUseCaseContract>(
      () => LoadNoteDraftUseCase(getIt()),
    )
    ..registerLazySingleton<SaveNoteDraftUseCaseContract>(
      () => SaveNoteDraftUseCase(getIt()),
    )
    ..registerLazySingleton<DiscardNoteDraftUseCaseContract>(
      () => DiscardNoteDraftUseCase(getIt()),
    )
    ..registerLazySingleton<GetUnassignedNotesUseCaseContract>(
      () => GetUnassignedNotesUseCase(getIt()),
    )
    ..registerLazySingleton<MoveNoteToSubjectUseCaseContract>(
      () => MoveNoteToSubjectUseCase(getIt()),
    )
    ..registerLazySingleton<GetQuestionBankUseCaseContract>(
      () => GetQuestionBankUseCase(getIt()),
    )
    ..registerLazySingleton<GetReviewHistoryUseCaseContract>(
      () => GetReviewHistoryUseCase(getIt()),
    )
    ..registerLazySingleton<GetReviewPreviewUseCaseContract>(
      () => GetReviewPreviewUseCase(getIt()),
    )
    ..registerLazySingleton<GetSharedNotesUseCaseContract>(
      () => GetSharedNotesUseCase(getIt()),
    )
    ..registerLazySingleton<GetSharedNoteUseCaseContract>(
      () => GetSharedNoteUseCase(getIt()),
    )
    ..registerLazySingleton<CopySharedNoteUseCaseContract>(
      () => CopySharedNoteUseCase(getIt()),
    )
    ..registerLazySingleton<GetStudyMaterialUseCaseContract>(
      () => GetStudyMaterialUseCase(getIt()),
    )
    ..registerLazySingleton<GetStudyMaterialsUseCaseContract>(
      () => GetStudyMaterialsUseCase(getIt()),
    )
    ..registerLazySingleton<GetSubjectFilesUseCaseContract>(
      () => GetSubjectFilesUseCase(getIt()),
    )
    ..registerLazySingleton<GetSubjectRetentionUseCaseContract>(
      () => GetSubjectRetentionUseCase(getIt()),
    )
    ..registerLazySingleton<GetSubjectSemesterUseCaseContract>(
      () => GetSubjectSemesterUseCase(getIt()),
    )
    ..registerLazySingleton<GetSubjectTimelineUseCaseContract>(
      () => GetSubjectTimelineUseCase(getIt()),
    )
    ..registerLazySingleton<GetSubjectUseCaseContract>(
      () => GetSubjectUseCase(getIt()),
    )
    ..registerLazySingleton<GetSubjectsUseCaseContract>(
      () => GetSubjectsUseCase(getIt()),
    )
    ..registerLazySingleton<GetTeachingGuideUseCaseContract>(
      () => GetTeachingGuideUseCase(getIt()),
    )
    ..registerLazySingleton<GetTestSessionUseCaseContract>(
      () => GetTestSessionUseCase(getIt()),
    )
    ..registerLazySingleton<GetTestSessionsUseCaseContract>(
      () => GetTestSessionsUseCase(getIt()),
    )
    ..registerLazySingleton<LoadOrGenerateStudyDocumentUseCaseContract>(
      () => LoadOrGenerateStudyDocumentUseCase(getIt()),
    )
    ..registerLazySingleton<RegisterStudyMaterialUseCaseContract>(
      () => RegisterStudyMaterialUseCase(getIt()),
    )
    ..registerLazySingleton<ExportFlashcardsToAnkiUseCaseContract>(
      () => ExportFlashcardsToAnkiUseCase(getIt()),
    )
    ..registerLazySingleton<ReviewFlashcardsUseCaseContract>(
      () => ReviewFlashcardsUseCase(getIt()),
    )
    ..registerLazySingleton<ReviewStudyMaterialUseCaseContract>(
      () => ReviewStudyMaterialUseCase(getIt()),
    )
    ..registerLazySingleton<SaveArtifactAsNoteUseCaseContract>(
      () => SaveArtifactAsNoteUseCase(getIt()),
    )
    ..registerLazySingleton<SaveArtifactAsQuizUseCaseContract>(
      () => SaveArtifactAsQuizUseCase(getIt()),
    )
    ..registerLazySingleton<SetAssessmentGradeUseCaseContract>(
      () => SetAssessmentGradeUseCase(getIt()),
    )
    ..registerLazySingleton<SetSubjectArchivedUseCaseContract>(
      () => SetSubjectArchivedUseCase(getIt()),
    )
    ..registerLazySingleton<SetSyllabusTopicCompletedUseCaseContract>(
      () => SetSyllabusTopicCompletedUseCase(getIt()),
    )
    ..registerLazySingleton<StartTestSessionUseCaseContract>(
      () => StartTestSessionUseCase(getIt()),
    )
    ..registerLazySingleton<GetMockExamOptionsUseCaseContract>(
      () => GetMockExamOptionsUseCase(getIt()),
    )
    ..registerLazySingleton<ReadNotePhotosUseCaseContract>(
      () => ReadNotePhotosUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateNoteUseCaseContract>(
      () => UpdateNoteUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateSubjectUseCaseContract>(
      () => UpdateSubjectUseCase(getIt()),
    )
    ..registerLazySingleton<UploadSubjectFileUseCaseContract>(
      () => UploadSubjectFileUseCase(getIt()),
    );
}
