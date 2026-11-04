import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_scan.freezed.dart';

/// Foto de una página de apuntes en papel, lista para enviar al servidor.
@freezed
abstract class NotePhotoUpload with _$NotePhotoUpload {
  const factory NotePhotoUpload({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) = _NotePhotoUpload;
}

/// Borrador de apunte leído de fotos: la persona lo revisa antes de guardar.
/// [tidied] dice si la IA lo ordenó; si no, es el texto tal como se leyó.
@freezed
abstract class ScannedNoteDraft with _$ScannedNoteDraft {
  const factory ScannedNoteDraft({
    String? title,
    required String markdown,
    required bool tidied,
    required int pages,
  }) = _ScannedNoteDraft;
}
