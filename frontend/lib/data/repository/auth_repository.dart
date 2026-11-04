import '../../domain/models/account/account.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/auth_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/session_drafts_cleaner.dart';
import '../local_data_source/token_storage.dart';
import '../remote_data_source/api/session_expiry_notifier.dart';
import '../remote_data_source/auth/auth_remote_data_source.dart';
import '../remote_data_source/auth/dto/auth_response_dto.dart';
import '../remote_data_source/auth/google_auth_data_source.dart';

class AuthRepository implements AuthRepositoryContract {
  AuthRepository({
    required this._remote,
    required this._google,
    required this._tokens,
    required this._expiry,
    this._drafts,
  });

  final AuthRemoteDataSource _remote;
  final GoogleAuthDataSource _google;
  final TokenStorage _tokens;
  final SessionExpiryNotifier _expiry;
  final SessionDraftsCleaner? _drafts;

  @override
  Future<AppResult<Account>> login({
    required String email,
    required String password,
  }) => RepositoryErrorHandler.guard(
    () async => _open(await _remote.login(email, password)),
  );

  @override
  Future<AppResult<Account>> register({
    required String email,
    required String password,
    required String fullName,
  }) => RepositoryErrorHandler.guard(
    () async => _open(await _remote.register(email, password, fullName)),
  );

  @override
  Future<AppResult<Account>> loginWithGoogle() =>
      RepositoryErrorHandler.guard(() async {
        final idToken = await _google.obtainIdToken();
        return _open(await _remote.loginWithGoogle(idToken));
      });

  @override
  Future<AppResult<Unit>> logout() => RepositoryErrorHandler.guard(() async {
    final tokens = await _tokens.read();
    await _tokens.clear();
    // Lo que la sesión en vivo dejó en el teléfono no debe verlo otra cuenta.
    await _drafts?.clear().catchError((Object _) {});
    await _google.signOut();
    if (tokens != null) {
      // La revocación en servidor es de mejor esfuerzo: la sesión local ya está cerrada.
      await _remote.logout(tokens.refreshToken).catchError((_) {});
    }
    return unit;
  });

  @override
  Future<AppResult<Unit>> requestPasswordReset({required String email}) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.requestPasswordReset(email);
        return unit;
      });

  @override
  Future<AppResult<Unit>> resetPassword({
    required String token,
    required String newPassword,
  }) => RepositoryErrorHandler.guard(() async {
    await _remote.resetPassword(token, newPassword);
    return unit;
  });

  @override
  Future<AppResult<Account?>> restoreSession() =>
      RepositoryErrorHandler.guard(() async {
        final tokens = await _tokens.read();
        if (tokens == null) return null;
        final account = await _remote.me();
        return account.toDomain();
      });

  @override
  Stream<Unit> watchSessionExpired() => _expiry.stream.map((_) => unit);

  Future<Account> _open(AuthResponseDto response) async {
    await _tokens.write((
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    ));
    return response.user.toDomain();
  }
}
