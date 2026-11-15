import '../enums/usage_focus.dart';
import '../enums/visibility.dart';
import '../models/account/account.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Cuenta del usuario autenticado.
abstract interface class AccountRepositoryContract {
  Future<AppResult<Account>> getAccount();

  /// Los parámetros nulos no cambian; [clearBirthDate] quita la fecha de
  /// nacimiento (es opcional).
  Future<AppResult<Account>> updateAccount({
    String? fullName,
    String? avatarUrl,
    Visibility? privacy,
    UsageFocus? usageFocus,
    DateTime? birthDate,
    bool clearBirthDate = false,
  });

  /// Sube la foto de perfil (`POST /me/avatar`) y devuelve la cuenta.
  Future<AppResult<Account>> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  });

  /// Quita la foto de perfil (`DELETE /me/avatar`) y devuelve la cuenta.
  Future<AppResult<Account>> removeAvatar();

  Future<AppResult<Unit>> changePassword({
    String? currentPassword,
    required String newPassword,
  });
}
