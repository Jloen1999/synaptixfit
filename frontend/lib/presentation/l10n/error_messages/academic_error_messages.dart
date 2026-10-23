import '../gen_l10n/app_localizations.dart';

/// Códigos de error del módulo academic (`docs/03-api/errors.md`).
String? academicErrorMessage(
  AppLocalizations l10n,
  String code,
) => switch (code) {
  'SUBJECT_NOT_FOUND' => l10n.academicErrorSubjectNotFound,
  'SUBJECT_CATALOG_NOT_FOUND' => l10n.academicErrorSubjectCatalogNotFound,
  'SUBJECT_SEMESTER_NOT_FOUND' => l10n.academicErrorSubjectSemesterNotFound,
  'NOTE_NOT_FOUND' => l10n.academicErrorNoteNotFound,
  'FILE_NOT_FOUND' => l10n.academicErrorFileNotFound,
  'FILE_TYPE_NOT_ALLOWED' => l10n.academicErrorFileTypeNotAllowed,
  'FILE_TOO_LARGE' => l10n.academicErrorFileTooLarge,
  'FILE_UPLOAD_INVALID' => l10n.academicErrorFileUploadInvalid,
  'FILE_ALREADY_REGISTERED' => l10n.academicErrorFileAlreadyRegistered,
  'STUDY_DOCUMENT_NOT_FOUND' => l10n.academicErrorStudyDocumentNotFound,
  'STUDY_SOURCE_NOT_SUPPORTED' => l10n.academicErrorStudySourceNotSupported,
  'STUDY_SOURCE_WITHOUT_SUBJECT' => l10n.academicErrorStudySourceWithoutSubject,
  'STUDY_GUIDE_EMPTY' => l10n.academicErrorStudyGuideEmpty,
  'TEACHING_GUIDE_IMPORT_NOT_FOUND' =>
    l10n.academicErrorTeachingGuideImportNotFound,
  'TEACHING_GUIDE_IMPORT_NOT_READY' =>
    l10n.academicErrorTeachingGuideImportNotReady,
  'TEACHING_GUIDE_IMPORT_ALREADY_APPLIED' =>
    l10n.academicErrorTeachingGuideImportAlreadyApplied,
  'STUDY_MATERIAL_NOT_FOUND' => l10n.academicErrorStudyMaterialNotFound,
  'QUIZ_BANK_NOT_FOUND' => l10n.academicErrorQuizBankNotFound,
  'QUIZ_BANK_EMPTY' => l10n.academicErrorQuizBankEmpty,
  'QUIZ_QUESTION_NOT_FOUND' => l10n.academicErrorQuizQuestionNotFound,
  'QUIZ_SESSION_NOT_FOUND' => l10n.academicErrorQuizSessionNotFound,
  'QUIZ_SESSION_NOT_IN_PROGRESS' => l10n.academicErrorQuizSessionNotInProgress,
  _ => null,
};
