import '../../../../domain/models/academic/note_scan.dart';
import '../../../widgets/photo_pick.dart';

export '../../../widgets/photo_pick.dart' show PhotoCameraUnavailable;

/// Lado más largo de la foto que se envía. A 2400 px la letra de una hoja
/// se lee bien y la foto pesa 1-2 MB (en vez de los 5-10 de la cámara).
const _maxSide = 2400.0;

/// Calidad JPEG al reducirla: por encima no se lee mejor y pesa el doble.
const _jpegQuality = 85;

/// Hace una foto de una página con la cámara (selector compartido
/// `photo_pick.dart`). `null` si se cancela; lanza [PhotoCameraUnavailable].
Future<NotePhotoUpload?> takeNotePhoto() async {
  final photo = await takePhoto(maxSide: _maxSide, quality: _jpegQuality);
  return photo == null ? null : _toUpload(photo);
}

/// Elige páginas de la galería (como mucho [limit]). Vacía si se cancela.
Future<List<NotePhotoUpload>> pickNotePhotos({required int limit}) async {
  final photos = await pickPhotos(
    limit: limit,
    maxSide: _maxSide,
    quality: _jpegQuality,
  );
  return [for (final p in photos) _toUpload(p)];
}

NotePhotoUpload _toUpload(PickedPhoto photo) => NotePhotoUpload(
  bytes: photo.bytes,
  fileName: photo.fileName,
  mimeType: photo.mimeType,
);
