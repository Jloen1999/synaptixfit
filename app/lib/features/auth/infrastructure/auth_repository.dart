import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';

class AuthResult {
  const AuthResult({
    required this.requiereOnboarding,
    required this.autenticado,
    this.error,
  });

  final bool requiereOnboarding;
  final bool autenticado;
  final String? error;
}

class AuthRepository {
  const AuthRepository();

  SupabaseClient get _client => Supabase.instance.client;

  bool get _modoMock => !EnvConfig.hasSupabase;

  bool _requiereOnboardingDesdeMetadata(User user) {
    final value = user.userMetadata?['onboarding_completado'];
    return value != true;
  }

  String _mapearErrorGoogleSignIn(PlatformException e) {
    final code = e.code.toLowerCase();
    final raw = (e.message ?? '').toLowerCase();

    if (code.contains('sign_in_canceled') || code.contains('canceled')) {
      return 'Inicio con Google cancelado por el usuario';
    }

    if (raw.contains('api exception: 10') || raw.contains('developer_error')) {
      return 'Google Sign-In rechazo la configuracion (DEVELOPER_ERROR). Verifica SHA-1 de Android, package name y GOOGLE_WEB_CLIENT_ID.';
    }

    if (raw.contains('12500') || raw.contains('sign_in_failed')) {
      return 'Fallo al autenticar con Google. Revisa que el proveedor Google en Supabase use el mismo Web Client ID y Secret de Google Cloud.';
    }

    if (raw.contains('network_error') || raw.contains('7')) {
      return 'Error de red al iniciar con Google. Comprueba conexion a internet y reintenta.';
    }

    return 'No fue posible iniciar con Google. Revisa la configuracion OAuth (SHA-1, package name y client IDs).';
  }

  Future<void> _reiniciarSesionGoogle(GoogleSignIn googleSignIn) async {
    try {
      await googleSignIn.disconnect();
    } catch (_) {
      // Si no existia una sesion conectada, se continua con signOut igualmente.
    }

    try {
      await googleSignIn.signOut();
    } catch (_) {
      // Si GoogleSignIn no tenia sesion local, no es un error funcional.
    }
  }

  Future<AuthResult> login(
      {required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) {
      return const AuthResult(
        requiereOnboarding: true,
        autenticado: false,
        error: 'Email y contrasena son obligatorios',
      );
    }

    if (_modoMock) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return const AuthResult(requiereOnboarding: false, autenticado: true);
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return const AuthResult(
          requiereOnboarding: true,
          autenticado: false,
          error: 'No fue posible iniciar sesion',
        );
      }

      return AuthResult(
        requiereOnboarding: _requiereOnboardingDesdeMetadata(user),
        autenticado: true,
      );
    } on AuthException catch (e) {
      return AuthResult(
        requiereOnboarding: true,
        autenticado: false,
        error: e.message,
      );
    } catch (_) {
      return const AuthResult(
        requiereOnboarding: true,
        autenticado: false,
        error: 'Error inesperado al iniciar sesion',
      );
    }
  }

  Future<AuthResult> registro(
      {required String email, required String password}) async {
    if (email.isEmpty || password.length < 8) {
      return const AuthResult(
        requiereOnboarding: true,
        autenticado: false,
        error: 'Contrasena invalida. Debe tener al menos 8 caracteres',
      );
    }

    if (_modoMock) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return const AuthResult(requiereOnboarding: true, autenticado: true);
    }

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final autenticado = response.session != null;
      if (!autenticado) {
        return const AuthResult(
          requiereOnboarding: true,
          autenticado: false,
          error: 'Revisa tu correo para confirmar tu cuenta antes de ingresar',
        );
      }

      return const AuthResult(requiereOnboarding: true, autenticado: true);
    } on AuthException catch (e) {
      return AuthResult(
        requiereOnboarding: true,
        autenticado: false,
        error: e.message,
      );
    } catch (_) {
      return const AuthResult(
        requiereOnboarding: true,
        autenticado: false,
        error: 'Error inesperado al crear la cuenta',
      );
    }
  }

  Future<AuthResult> loginConGoogle() async {
    if (_modoMock) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return const AuthResult(requiereOnboarding: true, autenticado: true);
    }

    try {
      if (kIsWeb) {
        final launched = await _client.auth.signInWithOAuth(
          OAuthProvider.google,
        );

        if (!launched) {
          return const AuthResult(
            requiereOnboarding: true,
            autenticado: false,
            error: 'No se pudo abrir el flujo de Google',
          );
        }

        return const AuthResult(
          requiereOnboarding: true,
          autenticado: false,
        );
      }

      if (!EnvConfig.hasGoogleWebClientId) {
        return const AuthResult(
          requiereOnboarding: true,
          autenticado: false,
          error:
              'Falta GOOGLE_WEB_CLIENT_ID en .env para Google Sign-In nativo',
        );
      }

      final googleSignIn = GoogleSignIn(
        scopes: const ['openid', 'email', 'profile'],
        clientId: defaultTargetPlatform == TargetPlatform.iOS &&
                EnvConfig.googleIosClientId.isNotEmpty
            ? EnvConfig.googleIosClientId
            : null,
        serverClientId: EnvConfig.googleWebClientId,
      );

      await _reiniciarSesionGoogle(googleSignIn);

      final cuenta = await googleSignIn.signIn();
      if (cuenta == null) {
        return const AuthResult(
          requiereOnboarding: true,
          autenticado: false,
          error: 'Inicio con Google cancelado por el usuario',
        );
      }

      final authGoogle = await cuenta.authentication;
      final idToken = authGoogle.idToken;
      final accessToken = authGoogle.accessToken;

      if (idToken == null || accessToken == null) {
        return const AuthResult(
          requiereOnboarding: true,
          autenticado: false,
          error: 'No se pudieron obtener credenciales de Google',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user == null) {
        return const AuthResult(
          requiereOnboarding: true,
          autenticado: false,
          error: 'No fue posible completar el inicio con Google',
        );
      }

      return AuthResult(
        requiereOnboarding: _requiereOnboardingDesdeMetadata(user),
        autenticado: true,
      );
    } on AuthException catch (e) {
      return AuthResult(
        requiereOnboarding: true,
        autenticado: false,
        error: e.message,
      );
    } on PlatformException catch (e) {
      debugPrint(
          'Google Sign-In PlatformException: code=${e.code}, message=${e.message}, details=${e.details}');
      return AuthResult(
        requiereOnboarding: true,
        autenticado: false,
        error: _mapearErrorGoogleSignIn(e),
      );
    } catch (e) {
      debugPrint('Google Sign-In error inesperado: $e');
      return const AuthResult(
        requiereOnboarding: true,
        autenticado: false,
        error:
            'No fue posible iniciar con Google. Revisa SHA-1, package name y GOOGLE_WEB_CLIENT_ID.',
      );
    }
  }

  Future<AuthResult> estadoSesionActual() async {
    if (_modoMock) {
      return const AuthResult(requiereOnboarding: true, autenticado: false);
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const AuthResult(
        requiereOnboarding: true,
        autenticado: false,
        error: 'No hay sesion activa',
      );
    }

    return AuthResult(
      requiereOnboarding: _requiereOnboardingDesdeMetadata(user),
      autenticado: true,
    );
  }

  Future<void> logout() async {
    if (_modoMock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return;
    }

    await _client.auth.signOut();
  }
}
