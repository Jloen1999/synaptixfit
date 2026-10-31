import '../../domain/enums/app_language.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/language_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/language_storage.dart';

/// Implementa [LanguageRepositoryContract] con [LanguageStorage].
class LanguageRepository implements LanguageRepositoryContract {
  LanguageRepository(this._storage);

  final LanguageStorage _storage;

  @override
  Future<AppResult<AppLanguage>> getLanguage() => RepositoryErrorHandler.guard(
    () async => AppLanguage.fromStorage(await _storage.read()),
  );

  @override
  Future<AppResult<Unit>> setLanguage(AppLanguage language) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.write(language.storageValue);
        return unit;
      });
}
