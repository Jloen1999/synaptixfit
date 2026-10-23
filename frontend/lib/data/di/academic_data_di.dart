import 'package:get_it/get_it.dart';

import '../../domain/repositories/note_repository_contract.dart';
import '../../domain/repositories/quiz_repository_contract.dart';
import '../../domain/repositories/study_assistant_repository_contract.dart';
import '../../domain/repositories/study_material_repository_contract.dart';
import '../../domain/repositories/subject_file_repository_contract.dart';
import '../../domain/repositories/subject_repository_contract.dart';
import '../../domain/repositories/teaching_guide_import_repository_contract.dart';
import '../remote_data_source/academic/files_remote_data_source.dart';
import '../remote_data_source/academic/notes_remote_data_source.dart';
import '../remote_data_source/academic/quiz_remote_data_source.dart';
import '../remote_data_source/academic/study_materials_remote_data_source.dart';
import '../remote_data_source/academic/study_remote_data_source.dart';
import '../remote_data_source/academic/subjects_remote_data_source.dart';
import '../remote_data_source/academic/teaching_guide_imports_remote_data_source.dart';
import '../repository/note_repository.dart';
import '../repository/quiz_repository.dart';
import '../repository/study_assistant_repository.dart';
import '../repository/study_material_repository.dart';
import '../repository/subject_file_repository.dart';
import '../repository/subject_repository.dart';
import '../repository/teaching_guide_import_repository.dart';

/// Data sources y repositorios del módulo academic.
void registerAcademicData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => SubjectsRemoteDataSource(getIt()))
    ..registerLazySingleton(() => NotesRemoteDataSource(getIt()))
    ..registerLazySingleton(() => FilesRemoteDataSource(getIt()))
    ..registerLazySingleton(() => StudyRemoteDataSource(getIt()))
    ..registerLazySingleton(() => StudyMaterialsRemoteDataSource(getIt()))
    ..registerLazySingleton(() => QuizRemoteDataSource(getIt()))
    ..registerLazySingleton(() => TeachingGuideImportsRemoteDataSource(getIt()))
    ..registerLazySingleton<SubjectRepositoryContract>(
      () => SubjectRepository(getIt()),
    )
    ..registerLazySingleton<NoteRepositoryContract>(
      () => NoteRepository(getIt()),
    )
    ..registerLazySingleton<SubjectFileRepositoryContract>(
      () => SubjectFileRepository(getIt()),
    )
    ..registerLazySingleton<StudyAssistantRepositoryContract>(
      () => StudyAssistantRepository(getIt()),
    )
    ..registerLazySingleton<StudyMaterialRepositoryContract>(
      () => StudyMaterialRepository(getIt()),
    )
    ..registerLazySingleton<QuizRepositoryContract>(
      () => QuizRepository(getIt()),
    )
    ..registerLazySingleton<TeachingGuideImportRepositoryContract>(
      () => TeachingGuideImportRepository(getIt(), getIt()),
    );
}
