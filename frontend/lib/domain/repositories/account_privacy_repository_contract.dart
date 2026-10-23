import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Autoservicio RGPD: exportar los datos propios y darse de baja.
abstract interface class AccountPrivacyRepositoryContract {
  /// Descarga el JSON con los datos del usuario y lo guarda donde elija.
  /// Devuelve `false` si el usuario cancela el guardado.
  Future<AppResult<bool>> exportMyData();

  /// Elimina la cuenta. Con contraseña si la cuenta la tiene; si es solo de
  /// Google, con [confirm] explícito.
  Future<AppResult<Unit>> deleteMyAccount({String? password, bool confirm});
}
