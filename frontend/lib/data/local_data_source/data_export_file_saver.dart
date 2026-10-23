import 'dart:convert';

import 'package:file_picker/file_picker.dart';

/// Guarda el fichero de exportación de datos: diálogo «Guardar como» en
/// escritorio y móvil, descarga directa en web.
class DataExportFileSaver {
  const DataExportFileSaver();

  /// Devuelve `false` si el usuario cancela.
  Future<bool> save({required String fileName, required String content}) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: utf8.encode(content),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    return uri != null;
  }
}
