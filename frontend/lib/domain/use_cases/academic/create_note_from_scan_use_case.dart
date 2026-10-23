import '../../models/academic/note.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Guarda texto escaneado o pegado como apunte.
abstract interface class CreateNoteFromScanUseCaseContract {
  Future<AppResult<Note>> call({
    required String title,
    required String text,
    String? subjectId,
  });
}

class CreateNoteFromScanUseCase implements CreateNoteFromScanUseCaseContract {
  const CreateNoteFromScanUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<Note>> call({
    required String title,
    required String text,
    String? subjectId,
  }) => _repository.createNoteFromScan(
    title: title,
    text: text,
    subjectId: subjectId,
  );
}
