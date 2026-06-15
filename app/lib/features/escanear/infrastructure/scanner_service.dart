import '../domain/escanear_result.dart';

/// Servicio abstracto para operaciones de escaneo OCR.
abstract class ScannerService {
  /// Escanea texto desde una imagen en [imagePath].
  Future<EscanearResult> scanText(String imagePath);
}

/// Implementacion que utiliza ML Kit (Google ML Kit Text Recognition).
///
/// Requiere configuracion nativa (Android/iOS) y el paquete
/// google_mlkit_text_recognition en pubspec.yaml.
/// Esta implementacion lanza [UnimplementedError] hasta que dichas dependencias
/// esten instaladas.
class MlKitScannerService implements ScannerService {
  @override
  Future<EscanearResult> scanText(String imagePath) async {
    throw UnimplementedError(
      'ML Kit no esta configurado. Instala google_mlkit_text_recognition.',
    );
  }
}

/// Implementacion para plataformas no soportadas (Web, escritorio).
/// Retorna un error descriptivo sin lanzar excepciones.
class UnsupportedScannerService implements ScannerService {
  @override
  Future<EscanearResult> scanText(String imagePath) async {
    return const EscanearResult(
      texto: null,
      error: 'Esta funcion requiere la app movil (Android/iOS).',
    );
  }
}
