import 'package:flutter/services.dart';
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

/// La cámara no se puede usar: sin permiso ([denied]) o el dispositivo no
/// tiene ([denied] falso). La pantalla lo explica y ofrece la galería.
class NotePhotoCameraUnavailable implements Exception {
  const NotePhotoCameraUnavailable({required this.denied});

  final bool denied;
}

/// Hace una foto con la cámara. `null` si se cancela. En web y escritorio,
/// donde no hay cámara del sistema, abre el selector de archivos. Lanza
/// [NotePhotoCameraUnavailable] si no hay permiso o no hay cámara.
Future<NotePhotoUpload?> takeNotePhoto() async {
  final XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _jpegQuality,
    );
  } on PlatformException catch (e) {
    if (e.code.contains('access_denied')) {
      throw const NotePhotoCameraUnavailable(denied: true);
    }
    if (e.code.contains('no_available_camera')) {
      throw const NotePhotoCameraUnavailable(denied: false);
    }
    rethrow;
  }
  return file == null ? null : _toUpload(file);
}

/// Elige fotos de la galería (como mucho [limit]). Lista vacía si se cancela.
Future<List<NotePhotoUpload>> pickNotePhotos({required int limit}) async {
  if (limit <= 0) return const [];
  // Con hueco para una sola, se elige una: si no, el selector deja marcar
  // varias y las de más se descartarían sin avisar.
  if (limit == 1) {
    final one = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _jpegQuality,
    );
    return one == null ? const [] : [await _toUpload(one)];
  }
  final files = await ImagePicker().pickMultiImage(
    maxWidth: _maxSide,
    maxHeight: _maxSide,
    imageQuality: _jpegQuality,
    limit: limit,
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
