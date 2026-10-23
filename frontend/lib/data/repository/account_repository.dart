import '../../domain/enums/usage_focus.dart';
import '../../domain/enums/visibility.dart';
import '../../domain/models/account/account.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/account_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/auth/auth_remote_data_source.dart';

class AccountRepository implements AccountRepositoryContract {
  AccountRepository(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<AppResult<Account>> getAccount() =>
      RepositoryErrorHandler.guard(() async => (await _remote.me()).toDomain());

  @override
  Future<AppResult<Account>> updateAccount({
    String? fullName,
    String? avatarUrl,
    Visibility? privacy,
    UsageFocus? usageFocus,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.updateMe({
      'fullName': ?fullName,
      'avatarUrl': ?avatarUrl,
      if (privacy != null) 'privacy': privacy.apiValue,
      if (usageFocus != null) 'usageFocus': usageFocus.apiValue,
    })).toDomain(),
  );

  @override
  Future<AppResult<Unit>> changePassword({
    String? currentPassword,
    required String newPassword,
  }) => RepositoryErrorHandler.guard(() async {
    await _remote.changePassword(currentPassword, newPassword);
    return unit;
  });
}
