import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/visibility.dart';

part 'material_sharing.freezed.dart';

/// A quién se ha pasado un apunte con «Compartir › Con un amigo» (ADR 0064).
@freezed
abstract class SentNote with _$SentNote {
  const factory SentNote({required String friendId, required String friendName}) =
      _SentNote;
}

/// Resultado de «Compartir › En el muro»: si ya estaba publicado y con qué
/// visibilidad quedó el apunte (la decide el servidor con el tope del perfil).
@freezed
abstract class NoteWallShare with _$NoteWallShare {
  const factory NoteWallShare({
    required bool alreadyShared,
    required Visibility visibility,
  }) = _NoteWallShare;
}

/// Un material listo para guardarlo en el teléfono o mandarlo fuera de la
/// app: el PDF de un apunte o el archivo original.
@freezed
abstract class MaterialFile with _$MaterialFile {
  const factory MaterialFile({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) = _MaterialFile;
}
