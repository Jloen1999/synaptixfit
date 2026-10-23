import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens de la sesión.
typedef SessionTokens = ({String accessToken, String refreshToken});

/// Almacén de tokens de sesión.
abstract interface class TokenStorage {
  Future<SessionTokens?> read();

  Future<void> write(SessionTokens tokens);

  Future<void> clear();
}

/// Guarda los tokens en el llavero del sistema (Keychain / Keystore / almacenamiento web).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'sfx_access_token';
  static const _refreshKey = 'sfx_refresh_token';

  final FlutterSecureStorage _storage;
  SessionTokens? _cache;

  @override
  Future<SessionTokens?> read() async {
    if (_cache != null) return _cache;
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    return _cache = (accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> write(SessionTokens tokens) async {
    _cache = tokens;
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    _cache = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
