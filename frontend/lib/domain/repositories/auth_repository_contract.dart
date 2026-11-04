import '../models/account/account.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Autenticación y sesión.
abstract interface class AuthRepositoryContract {
  Future<AppResult<Account>> login({
    required String email,
    required String password,
  });

  /// [acceptedLegalVersion] es la versión de la política que la persona
  /// aceptó en el formulario: el servidor la guarda con el alta (ADR 0034).
  Future<AppResult<Account>> register({
    required String email,
    required String password,
    required String fullName,
    String? acceptedLegalVersion,
  });

  /// Inicia sesión con Google. En web espera a que el usuario pulse el botón de Google.
  Future<AppResult<Account>> loginWithGoogle();

  Future<AppResult<Unit>> logout();

  /// Envía el correo para restablecer la contraseña (siempre éxito si el
  /// servidor responde: no revela si la cuenta existe).
  Future<AppResult<Unit>> requestPasswordReset({required String email});

  /// Contraseña nueva con el token del enlace del correo.
  Future<AppResult<Unit>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Recupera la sesión guardada. Devuelve `null` si no hay sesión.
  Future<AppResult<Account?>> restoreSession();

  /// Emite cuando la sesión caduca y no se puede renovar.
  Stream<Unit> watchSessionExpired();
}
