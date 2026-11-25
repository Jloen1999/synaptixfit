import 'dart:typed_data';

import '../models/academic/material_sharing.dart';
import '../models/result/app_result.dart';

/// Comparte contenido fuera de la app con el menú del sistema (WhatsApp,
/// Instagram…). En web, si el navegador no puede, descarga el archivo.
abstract interface class ShareRepositoryContract {
  /// Devuelve `false` si la persona cerró el menú sin compartir.
  Future<AppResult<bool>> shareImage({
    required Uint8List png,
    required String fileName,
    required String text,
  });

  /// Comparte un texto (p. ej. un enlace). `false` si se cancela.
  Future<AppResult<bool>> shareText({required String text, String? subject});

  /// Comparte un archivo (el PDF de un apunte o el original, ADR 0064).
  /// `false` si se cancela.
  Future<AppResult<bool>> shareFile(MaterialFile file);
}
