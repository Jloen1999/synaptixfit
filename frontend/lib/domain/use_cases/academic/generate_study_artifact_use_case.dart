import '../../enums/artifact_kind.dart';
import '../../models/academic/study_artifact.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_assistant_repository_contract.dart';

/// Genera un resultado efímero a partir de varias fuentes.
abstract interface class GenerateStudyArtifactUseCaseContract {
  Future<AppResult<StudyArtifact>> call(
    ArtifactKind kind,
    List<StudySourceRef> sources,
  );
}

class GenerateStudyArtifactUseCase
    implements GenerateStudyArtifactUseCaseContract {
  const GenerateStudyArtifactUseCase(this._repository);

  final StudyAssistantRepositoryContract _repository;

  @override
  Future<AppResult<StudyArtifact>> call(
    ArtifactKind kind,
    List<StudySourceRef> sources,
  ) => _repository.generateArtifact(kind, sources);
}
