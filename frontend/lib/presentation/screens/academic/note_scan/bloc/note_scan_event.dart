part of 'note_scan_bloc.dart';

@freezed
sealed class NoteScanEvent with _$NoteScanEvent {
  /// [subjectId]: asignatura propuesta (si se abre desde una asignatura).
  const factory NoteScanEvent.started({String? subjectId}) = NoteScanStarted;

  const factory NoteScanEvent.photosAdded(List<NotePhotoUpload> photos) =
      NoteScanPhotosAdded;

  const factory NoteScanEvent.photoRemoved(int index) = NoteScanPhotoRemoved;

  /// Envía las fotos para leerlas.
  const factory NoteScanEvent.readRequested() = NoteScanReadRequested;

  /// Vuelve a las fotos (para añadir o quitar alguna y leer otra vez).
  const factory NoteScanEvent.backToPhotos() = NoteScanBackToPhotos;

  const factory NoteScanEvent.subjectChanged(String? subjectId) =
      NoteScanSubjectChanged;

  /// Guarda el texto revisado como apunte.
  const factory NoteScanEvent.saveRequested({
    required String title,
    required String markdown,
  }) = NoteScanSaveRequested;
}
