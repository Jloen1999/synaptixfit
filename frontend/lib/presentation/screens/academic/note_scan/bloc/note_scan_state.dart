part of 'note_scan_bloc.dart';

/// Por qué no se pudo usar la cámara.
enum NoteScanCameraProblem { denied, missing }

@freezed
abstract class NoteScanState with _$NoteScanState {
  const factory NoteScanState({
    @Default(<Subject>[]) List<Subject> subjects,
    String? subjectId,
    @Default(<NotePhotoUpload>[]) List<NotePhotoUpload> photos,
    NoteScanCameraProblem? cameraProblem,
    @Default(false) bool reading,
    AppError? readError,

    /// Texto leído, pendiente de revisar; con él la pantalla pasa a revisión.
    ScannedNoteDraft? draft,
    @Default(false) bool saving,
    AppError? saveError,

    /// Apunte creado: la pantalla lo abre.
    String? savedNoteId,
  }) = _NoteScanState;

  const NoteScanState._();

  /// Mismo límite de entrada que el servidor (`NotePhoto.MAX_PHOTOS`): se
  /// aplica aquí para no dejar elegir fotos que luego se rechazarían.
  static const maxPhotos = 5;

  bool get canAddMore => photos.length < maxPhotos;

  int get room => maxPhotos - photos.length;
}
