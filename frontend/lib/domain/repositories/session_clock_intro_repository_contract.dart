import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Preferencia local: explicar o no el cronómetro al empezar una sesión.
abstract interface class SessionClockIntroRepositoryContract {
  Future<AppResult<bool>> isHidden();

  Future<AppResult<Unit>> hide();
}
