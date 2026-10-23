import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

import '../../errors/custom_error.dart';

/// Obtiene un ID token de Google.
///
/// En Android/iOS lanza el flujo nativo. En web, Google exige su propio botón
/// (lo pinta la presentación): aquí se espera al evento de autenticación que
/// ese botón genera.
class GoogleAuthDataSource {
  GoogleAuthDataSource({this._clientId, this._serverClientId});

  final String? _clientId;
  final String? _serverClientId;
  Future<void>? _initialization;

  Future<void> _ensureInitialized() => _initialization ??= GoogleSignIn.instance
      .initialize(clientId: _clientId, serverClientId: _serverClientId);

  Future<String> obtainIdToken() async {
    try {
      await _ensureInitialized();
    } catch (e) {
      _initialization = null; // permite reintentar
      throw CustomError('GOOGLE_SIGN_IN_FAILED', '$e');
    }
    final signIn = GoogleSignIn.instance;
    final GoogleSignInAccount account;
    if (signIn.supportsAuthenticate()) {
      try {
        account = await signIn.authenticate();
      } on GoogleSignInException catch (e) {
        throw CustomError(
          e.code == GoogleSignInExceptionCode.canceled
              ? 'GOOGLE_SIGN_IN_CANCELLED'
              : 'GOOGLE_SIGN_IN_FAILED',
          e.description,
        );
      }
    } else {
      account = await signIn.authenticationEvents
          .where((e) => e is GoogleSignInAuthenticationEventSignIn)
          .map((e) => (e as GoogleSignInAuthenticationEventSignIn).user)
          .first;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const CustomError('GOOGLE_SIGN_IN_FAILED', 'No ID token');
    }
    return idToken;
  }

  Future<void> signOut() async {
    if (_initialization == null) return;
    await GoogleSignIn.instance.signOut();
  }
}
