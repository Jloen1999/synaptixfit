import 'package:file_picker/file_picker.dart';

import '../../../../domain/models/academic/subject_file.dart';

/// Tamaño máximo admitido por la API (25 MB).
const maxUploadBytes = 25 * 1024 * 1024;

/// Resultado de elegir un archivo.
sealed class PickedFile {
  const PickedFile();
}

final class PickedPayload extends PickedFile {
  const PickedPayload(this.payload);

  final FileUploadPayload payload;
}

/// El archivo supera [maxUploadBytes].
final class PickedTooLarge extends PickedFile {
  const PickedTooLarge();
}

const _mimeByExtension = {
  'pdf': 'application/pdf',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'gif': 'image/gif',
  'heic': 'image/heic',
  'txt': 'text/plain',
  'md': 'text/markdown',
  'csv': 'text/csv',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx':
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'zip': 'application/zip',
};

/// Tamaño máximo de un plan docente (lo mismo que acepta la API).
const maxGuidePdfBytes = 15 * 1024 * 1024;

/// Selector limitado a PDF para el plan docente. `null` si se cancela.
Future<PickedFile?> pickPdfFile() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  if (file == null) return null;
  final size = await file.length();
  if (size != null && size > maxGuidePdfBytes) return const PickedTooLarge();
  final bytes = await file.readAsBytes();
  if (bytes.length > maxGuidePdfBytes) return const PickedTooLarge();
  return PickedPayload(
    FileUploadPayload(
      fileName: file.name,
      mimeType: 'application/pdf',
      bytes: bytes,
    ),
  );
}

/// Abre el selector de archivos. Devuelve `null` si el usuario cancela.
Future<PickedFile?> pickUploadFile() async {
  final file = await FilePicker.pickFile();
  if (file == null) return null;
  final size = await file.length();
  if (size != null && size > maxUploadBytes) return const PickedTooLarge();
  final bytes = await file.readAsBytes();
  if (bytes.length > maxUploadBytes) return const PickedTooLarge();
  final extension = file.extension?.toLowerCase();
  return PickedPayload(
    FileUploadPayload(
      fileName: file.name,
      mimeType: _mimeByExtension[extension] ?? 'application/octet-stream',
      bytes: bytes,
    ),
  );
}
