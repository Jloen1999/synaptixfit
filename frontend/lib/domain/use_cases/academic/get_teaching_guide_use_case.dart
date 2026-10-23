import '../../errors/app_error.dart';
import '../../models/academic/teaching_guide.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Guía docente de la asignatura o `null` si aún no se ha generado.
abstract interface class GetTeachingGuideUseCaseContract {
  Future<AppResult<TeachingGuide?>> call(String subjectId);
}

class GetTeachingGuideUseCase implements GetTeachingGuideUseCaseContract {
  const GetTeachingGuideUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<TeachingGuide?>> call(String subjectId) async {
    final result = await _repository.getTeachingGuide(subjectId);
    return switch (result) {
      Success(:final value) => Success(value),
      Failure(:final error) when isMissingStudyDocument(error) => const Success(
        null,
      ),
      Failure(:final error) => Failure(error),
    };
  }
}

/// El documento de IA (o la guía) todavía no existe.
bool isMissingStudyDocument(AppError error) =>
    error is NotFoundError ||
    error == const AppError.business('STUDY_DOCUMENT_NOT_FOUND');
