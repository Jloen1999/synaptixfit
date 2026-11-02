import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/session_clock_intro_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/session_clock_intro_storage.dart';

/// Implementa [SessionClockIntroRepositoryContract] con
/// [SessionClockIntroStorage].
class SessionClockIntroRepository
    implements SessionClockIntroRepositoryContract {
  const SessionClockIntroRepository(this._storage);

  final SessionClockIntroStorage _storage;

  @override
  Future<AppResult<bool>> isHidden() =>
      RepositoryErrorHandler.guard(_storage.isHidden);

  @override
  Future<AppResult<Unit>> hide() => RepositoryErrorHandler.guard(() async {
    await _storage.hide();
    return unit;
  });
}
