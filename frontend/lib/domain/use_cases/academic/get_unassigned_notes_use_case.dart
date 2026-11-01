import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Apuntes sin asignatura (la bandeja de notas rápidas de Académico), los más
/// recientes primero. El filtro lo aplica el servidor.
abstract interface class GetUnassignedNotesUseCaseContract {
  Future<AppResult<List<Note>>> call();
}

class GetUnassignedNotesUseCase implements GetUnassignedNotesUseCaseContract {
  const GetUnassignedNotesUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<List<Note>>> call() => _repository.getUnassignedNotes();
}
