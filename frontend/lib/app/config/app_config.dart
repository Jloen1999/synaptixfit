import 'package:flutter/foundation.dart';

/// Configuración de compilación (`--dart-define`).
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.googleClientId,
    this.googleServerClientId,
  });

  factory AppConfig.fromEnvironment() => AppConfig(
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
    googleClientId: _orNull(const String.fromEnvironment('GOOGLE_CLIENT_ID')),
    googleServerClientId: _orNull(
      const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    ),
  );

  /// URL base del backend, sin barra final.
  final String apiBaseUrl;

  /// ID de cliente OAuth de Google para web/iOS.
  final String? googleClientId;

  /// ID de cliente web de Google: Android lo necesita para obtener el ID token.
  final String? googleServerClientId;

  /// En web, Google exige un ID de cliente: sin `GOOGLE_CLIENT_ID` no se ofrece el
  /// botón. En móvil la configuración nativa (plist / google-services) basta.
  bool get googleSignInAvailable => !kIsWeb || googleClientId != null;

  static String? _orNull(String value) => value.isEmpty ? null : value;
}
