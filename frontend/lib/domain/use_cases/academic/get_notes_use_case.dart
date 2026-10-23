import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Apuntes del usuario (opcionalmente de una asignatura).
abstract interface class GetNotesUseCaseContract {
  Future<AppResult<List<Note>>> call({String? subjectId});
}

class GetNotesUseCase implements GetNotesUseCaseContract {
  const GetNotesUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<List<Note>>> call({String? subjectId}) =>
      _repository.getNotes(subjectId: subjectId);
}
