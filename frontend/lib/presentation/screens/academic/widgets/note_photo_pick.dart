import 'package:image_picker/image_picker.dart';

import '../../../../domain/models/academic/note_scan.dart';

/// Lado más largo de la foto que se envía. A 2400 px la letra de una hoja
/// se lee bien y la foto pesa 1-2 MB (en vez de los 5-10 de la cámara).
const _maxSide = 2400.0;

/// Calidad JPEG al reducirla: por encima no se lee mejor y pesa el doble.
const _jpegQuality = 85;

const _mimeByExtension = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

/// Hace una foto con la cámara. `null` si se cancela. En web y escritorio,
/// donde no hay cámara del sistema, abre el selector de archivos.
Future<NotePhotoUpload?> takeNotePhoto() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: _maxSide,
    maxHeight: _maxSide,
    imageQuality: _jpegQuality,
  );
  return file == null ? null : _toUpload(file);
}

/// Elige fotos de la galería (como mucho [limit]). Lista vacía si se cancela.
Future<List<NotePhotoUpload>> pickNotePhotos({required int limit}) async {
  if (limit <= 0) return const [];
  final files = await ImagePicker().pickMultiImage(
    maxWidth: _maxSide,
    maxHeight: _maxSide,
    imageQuality: _jpegQuality,
    limit: limit > 1 ? limit : null,
  );
  return [for (final f in files.take(limit)) await _toUpload(f)];
}

Future<NotePhotoUpload> _toUpload(XFile file) async {
  final extension = file.name.split('.').last.toLowerCase();
  return NotePhotoUpload(
    bytes: await file.readAsBytes(),
    fileName: file.name,
    // Al reducirla, image_picker la guarda como JPEG en el móvil.
    mimeType: file.mimeType ?? _mimeByExtension[extension] ?? 'image/jpeg',
  );
}
