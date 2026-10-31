import '../enums/appearance_mode.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Preferencia de apariencia de este dispositivo.
abstract interface class AppearanceRepositoryContract {
  Future<AppResult<AppearanceMode>> getMode();

  Future<AppResult<Unit>> setMode(AppearanceMode mode);
}
