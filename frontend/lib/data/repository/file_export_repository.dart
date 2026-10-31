import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/file_export_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/data_export_file_saver.dart';

/// Implementa [FileExportRepositoryContract] con [DataExportFileSaver]; un
/// fallo del sistema de archivos llega como [AppResult] de error.
class FileExportRepository implements FileExportRepositoryContract {
  const FileExportRepository(this._saver);

  final DataExportFileSaver _saver;

  @override
  Future<AppResult<bool>> saveText({
    required String fileName,
    required String content,
    required String mimeType,
    required String extension,
  }) => RepositoryErrorHandler.guard(
    () => _saver.save(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
      extension: extension,
    ),
  );
}
