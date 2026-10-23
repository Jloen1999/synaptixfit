import '../../models/academic/mind_map.dart';
import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_assistant_repository_contract.dart';

/// Guarda un resumen o mapa mental generado como apunte.
abstract interface class SaveArtifactAsNoteUseCaseContract {
  Future<AppResult<Note>> call({
    String? subjectId,
    String? title,
    String? markdown,
    MindMap? mindMap,
  });
}

class SaveArtifactAsNoteUseCase implements SaveArtifactAsNoteUseCaseContract {
  const SaveArtifactAsNoteUseCase(this._repository);

  final StudyAssistantRepositoryContract _repository;

  @override
  Future<AppResult<Note>> call({
    String? subjectId,
    String? title,
    String? markdown,
    MindMap? mindMap,
  }) => _repository.saveArtifactAsNote(
    subjectId: subjectId,
    title: title,
    markdown: markdown,
    mindMap: mindMap,
  );
}
