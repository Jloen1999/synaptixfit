import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/account/picked_photo.dart';

export '../../domain/models/account/picked_photo.dart';

const _mimeByExtension = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

/// La cámara no se puede usar: sin permiso ([denied]) o el dispositivo no
/// tiene ([denied] falso). La pantalla lo explica y ofrece la galería.
class PhotoCameraUnavailable implements Exception {
  const PhotoCameraUnavailable({required this.denied});

  final bool denied;
}

/// ¿Hay cámara del sistema? Solo en Android e iOS: en la web y el escritorio
/// `image_picker` abre el selector de archivos.
bool get canTakePhotos =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Hace una foto con la cámara, reducida a [maxSide] px y en JPEG de
/// [quality]. `null` si se cancela. La orientación la corrige el servidor
/// (ADR 0051): `image_picker` reduce la foto sin girar los píxeles. Lanza
/// [PhotoCameraUnavailable] si no hay permiso o no hay cámara.
Future<PickedPhoto?> takePhoto({
  required double maxSide,
  required int quality,
  bool frontCamera = false,
}) async {
  final XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: frontCamera
          ? CameraDevice.front
          : CameraDevice.rear,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
    );
  } on PlatformException catch (e) {
    if (e.code.contains('access_denied')) {
      throw const PhotoCameraUnavailable(denied: true);
    }
    if (e.code.contains('no_available_camera')) {
      throw const PhotoCameraUnavailable(denied: false);
    }
    rethrow;
  }
  return file == null ? null : _toPhoto(file);
}

/// Elige fotos de la galería (como mucho [limit]). Lista vacía si se cancela.
Future<List<PickedPhoto>> pickPhotos({
  required int limit,
  required double maxSide,
  required int quality,
}) async {
  if (limit <= 0) return const [];
  // Con hueco para una sola, se elige una: si no, el selector deja marcar
  // varias y las de más se descartarían sin avisar.
  if (limit == 1) {
    final one = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
    );
    return one == null ? const [] : [await _toPhoto(one)];
  }
  final files = await ImagePicker().pickMultiImage(
    maxWidth: maxSide,
    maxHeight: maxSide,
    imageQuality: quality,
    limit: limit,
  );
  return [for (final f in files.take(limit)) await _toPhoto(f)];
}

Future<PickedPhoto> _toPhoto(XFile file) async {
  final extension = file.name.split('.').last.toLowerCase();
  return (
    bytes: await file.readAsBytes(),
    fileName: file.name,
    // Al reducirla, image_picker la guarda como JPEG en el móvil.
    mimeType: file.mimeType ?? _mimeByExtension[extension] ?? 'image/jpeg',
  );
}
