import 'package:flutter/foundation.dart';

/// Configuración de compilación (`--dart-define`).
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.googleClientId,
    this.googleServerClientId,
    this.mapTilesKey,
    this.mapTilesUrl = defaultMapTilesUrl,
  });

  /// Teselas ráster de MapTiler (256 px); `{key}` se cambia por [mapTilesKey].
  static const defaultMapTilesUrl =
      'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key={key}';

  factory AppConfig.fromEnvironment() => AppConfig(
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
    googleClientId: _orNull(const String.fromEnvironment('GOOGLE_CLIENT_ID')),
    googleServerClientId: _orNull(
      const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    ),
    mapTilesKey: _orNull(const String.fromEnvironment('MAP_TILES_KEY')),
    mapTilesUrl:
        _orNull(const String.fromEnvironment('MAP_TILES_URL')) ??
        defaultMapTilesUrl,
  );

  /// URL base del backend, sin barra final.
  final String apiBaseUrl;

  /// ID de cliente OAuth de Google para web/iOS.
  final String? googleClientId;

  /// ID de cliente web de Google: Android lo necesita para obtener el ID token.
  final String? googleServerClientId;

  /// Clave del proveedor de mapas (`MAP_TILES_KEY`, ADR 0037). Sin ella, la
  /// ruta se dibuja sobre un fondo liso con «Mapa no disponible».
  final String? mapTilesKey;

  /// Plantilla de las teselas (`MAP_TILES_URL`) para poder cambiar de
  /// proveedor sin tocar código: `{z}`, `{x}`, `{y}` y `{key}`.
  final String mapTilesUrl;

  bool get mapAvailable => mapTilesKey != null;

  /// En web, Google exige un ID de cliente: sin `GOOGLE_CLIENT_ID` no se ofrece el
  /// botón. En móvil la configuración nativa (plist / google-services) basta.
  bool get googleSignInAvailable => !kIsWeb || googleClientId != null;

  static String? _orNull(String value) => value.isEmpty ? null : value;
}
