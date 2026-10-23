import '../models/account/account.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Autenticación y sesión.
abstract interface class AuthRepositoryContract {
  Future<AppResult<Account>> login({
    required String email,
    required String password,
  });

  Future<AppResult<Account>> register({
    required String email,
    required String password,
    required String fullName,
  });

  /// Inicia sesión con Google. En web espera a que el usuario pulse el botón de Google.
  Future<AppResult<Account>> loginWithGoogle();

  Future<AppResult<Unit>> logout();

  /// Recupera la sesión guardada. Devuelve `null` si no hay sesión.
  Future<AppResult<Account?>> restoreSession();

  /// Emite cuando la sesión caduca y no se puede renovar.
  Stream<Unit> watchSessionExpired();
}
