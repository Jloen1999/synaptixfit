import '../../domain/enums/guide_id.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/guide_progress_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/guide_progress_storage.dart';

/// Implementa [GuideProgressRepositoryContract] con [GuideProgressStorage].
class GuideProgressRepository implements GuideProgressRepositoryContract {
  const GuideProgressRepository(this._storage);

  final GuideProgressStorage _storage;

  @override
  Future<AppResult<Set<GuideId>>> seen(String accountId) =>
      RepositoryErrorHandler.guard(() async {
        final names = await _storage.read(accountId);
        // Un nombre que esta versión no conoce (de otra más nueva) se ignora.
        return {
          for (final guide in GuideId.values)
            if (names.contains(guide.name)) guide,
        };
      });

  @override
  Future<AppResult<Unit>> markSeen(String accountId, GuideId guide) =>
      RepositoryErrorHandler.guard(() async {
        final names = await _storage.read(accountId);
        if (!names.contains(guide.name)) {
          await _storage.write(accountId, [...names, guide.name]);
        }
        return unit;
      });

  @override
  Future<AppResult<Unit>> reset(String accountId) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.clear(accountId);
        return unit;
      });
}
