import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Guarda ficheros de texto que exporta la app (datos del usuario, mazos de
/// Anki): diálogo «Guardar como» en escritorio y móvil, descarga en web.
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
}
