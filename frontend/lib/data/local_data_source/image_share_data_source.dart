import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Abre el menú de compartir del sistema con una imagen PNG (share_plus). En
/// web usa la API de compartir del navegador y, si no existe, la descarga.
class ImageShareDataSource {
  const ImageShareDataSource();

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
}
