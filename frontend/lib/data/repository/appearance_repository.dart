import '../../domain/enums/appearance_mode.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/appearance_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/appearance_storage.dart';

/// Implementa [AppearanceRepositoryContract] con [AppearanceStorage].
class AppearanceRepository implements AppearanceRepositoryContract {
  AppearanceRepository(this._storage);

  final AppearanceStorage _storage;

  @override
  Future<AppResult<AppearanceMode>> getMode() => RepositoryErrorHandler.guard(
    () async => AppearanceMode.fromStorage(await _storage.read()),
  );

  @override
  Future<AppResult<Unit>> setMode(AppearanceMode mode) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.write(mode.storageValue);
        return unit;
      });
}
