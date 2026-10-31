import '../models/result/app_result.dart';

/// Guarda en el dispositivo un fichero de texto generado por la app (diálogo
/// «Guardar como» o descarga en web). Lo usan las exportaciones locales.
abstract interface class FileExportRepositoryContract {
  /// Devuelve `false` si el usuario cancela el guardado.
  Future<AppResult<bool>> saveText({
    required String fileName,
    required String content,
    required String mimeType,
    required String extension,
  });
}
