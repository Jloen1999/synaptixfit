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

  Future<AppResult<Unit>> changePassword({
    String? currentPassword,
    required String newPassword,
  });
}
