import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/training/wod.dart';
import '../../domain/repositories/wod_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/training/wod_remote_data_source.dart';

/// Implementa [WodRepositoryContract] con [WodRemoteDataSource].
class WodRepository implements WodRepositoryContract {
  const WodRepository(this._remote);

  final WodRemoteDataSource _remote;

  @override
  Future<AppResult<List<Wod>>> listTemplates() =>
      RepositoryErrorHandler.guard(_remote.listTemplates);

  @override
  Future<AppResult<WodBoard>> board({String? templateCode}) =>
      RepositoryErrorHandler.guard(
        () => _remote.board(templateCode: templateCode),
      );

  @override
  Future<AppResult<Wod>> create(Wod wod) =>
      RepositoryErrorHandler.guard(() => _remote.create(wod));

  @override
  Future<AppResult<Wod>> update(Wod wod) =>
      RepositoryErrorHandler.guard(() => _remote.update(wod));

  @override
  Future<AppResult<Unit>> delete(String wodId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.delete(wodId);
        return unit;
      });

  @override
  Future<AppResult<WodMark>> saveResult(Wod wod, WodResultDraft draft) =>
      RepositoryErrorHandler.guard(() => _remote.saveResult(wod, draft));

  @override
  Future<AppResult<List<WodMark>>> listMarks() =>
      RepositoryErrorHandler.guard(_remote.listMarks);
}
