import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Guarda ficheros que exporta la app (datos del usuario, mazos de Anki,
/// apuntes en PDF y archivos de una asignatura): diálogo «Guardar como» en
/// escritorio y móvil, descarga en web.
class DataExportFileSaver {
  const DataExportFileSaver();

  /// Devuelve `false` si el usuario cancela.
  Future<bool> save({
    required String fileName,
    required String content,
    String mimeType = 'application/json',
    String extension = 'json',
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: utf8.encode(content),
      mimeType: mimeType,
      type: FileType.custom,
      allowedExtensions: [extension],
    );
    // En web el navegador descarga directamente (no hay diálogo que cancelar)
    // y file_picker devuelve null aunque haya guardado.
    return kIsWeb || uri != null;
  }

  /// Guarda un archivo binario (un PDF, una foto…) con su nombre (ADR 0064).
  /// Devuelve `false` si el usuario cancela.
  Future<bool> saveBytes({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final dot = fileName.lastIndexOf('.');
    final extension = dot < 0 ? null : fileName.substring(dot + 1).toLowerCase();
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      type: extension == null ? FileType.any : FileType.custom,
      allowedExtensions: extension == null ? null : [extension],
    );
    return kIsWeb || uri != null;
  }
}
