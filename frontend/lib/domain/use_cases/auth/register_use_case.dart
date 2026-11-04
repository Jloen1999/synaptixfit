import '../../models/account/account.dart';
import '../../models/result/app_result.dart';
import '../../repositories/auth_repository_contract.dart';

abstract interface class RegisterUseCaseContract {
  Future<AppResult<Account>> call({
    required String email,
    required String password,
    required String fullName,
    String? acceptedLegalVersion,
  });
}

class RegisterUseCase implements RegisterUseCaseContract {
  const RegisterUseCase(this._repository);

  final AuthRepositoryContract _repository;

  @override
  Future<AppResult<Account>> call({
    required String email,
    required String password,
    required String fullName,
    String? acceptedLegalVersion,
  }) => _repository.register(
    email: email.trim(),
    password: password,
    fullName: fullName.trim(),
    acceptedLegalVersion: acceptedLegalVersion,
  );
}
