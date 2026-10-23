import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/account_privacy_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/data_export_file_saver.dart';
import '../remote_data_source/profile/account_privacy_remote_data_source.dart';

class AccountPrivacyRepository implements AccountPrivacyRepositoryContract {
  AccountPrivacyRepository(this._remote, this._saver);

  final AccountPrivacyRemoteDataSource _remote;
  final DataExportFileSaver _saver;

  @override
  Future<AppResult<bool>> exportMyData() =>
      RepositoryErrorHandler.guard(() async {
        final file = await _remote.export();
        return _saver.save(fileName: file.fileName, content: file.content);
      });

  @override
  Future<AppResult<Unit>> deleteMyAccount({
    String? password,
    bool confirm = false,
  }) => RepositoryErrorHandler.guard(() async {
    await _remote.deleteAccount(password: password, confirm: confirm);
    return unit;
  });
}
