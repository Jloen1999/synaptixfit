import '../../models/academic/note_scan.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';

/// Convierte fotos de apuntes en papel en un borrador de apunte para revisar.
abstract interface class ReadNotePhotosUseCaseContract {
  Future<AppResult<ScannedNoteDraft>> call(List<NotePhotoUpload> photos);
}

class ReadNotePhotosUseCase implements ReadNotePhotosUseCaseContract {
  const ReadNotePhotosUseCase(this._repository);

  final NoteRepositoryContract _repository;

  @override
  Future<AppResult<ScannedNoteDraft>> call(List<NotePhotoUpload> photos) =>
      _repository.readNotePhotos(photos);
}
