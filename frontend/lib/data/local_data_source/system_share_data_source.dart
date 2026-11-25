import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Abre el menú de compartir del sistema (share_plus) con una imagen PNG o con
/// un texto. En web usa la API de compartir del navegador y, si no existe, la
/// descarga (imagen) o el portapapeles (texto, lo decide share_plus).
class SystemShareDataSource {
  const SystemShareDataSource();

  /// `false` si la persona cerró el menú sin compartir.
  Future<bool> sharePng({
    required Uint8List png,
    required String fileName,
    required String text,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile.fromData(png, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }

  /// `false` si la persona cerró el menú sin compartir.
  Future<bool> shareText({required String text, String? subject}) async {
    final result = await SharePlus.instance.share(
      ShareParams(text: text, subject: subject),
    );
    return result.status != ShareResultStatus.dismissed;
  }

  /// Un archivo cualquiera (el PDF de un apunte o el original, ADR 0064).
  /// `false` si la persona cerró el menú sin compartir.
  Future<bool> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }
}
