import '../../enums/usage_focus.dart';
import '../../enums/visibility.dart';
import '../../models/account/account.dart';
import '../../models/result/app_result.dart';
import '../../repositories/account_repository_contract.dart';

/// Guarda los cambios de la cuenta: nombre, foto, privacidad, modo de uso y
/// fecha de nacimiento (ADR 0036). Los nulos no cambian.
abstract interface class UpdateAccountUseCaseContract {
  Future<AppResult<Account>> call({
    String? fullName,
    String? avatarUrl,
    Visibility? privacy,
    UsageFocus? usageFocus,
    DateTime? birthDate,
    bool clearBirthDate = false,
  });
}

class UpdateAccountUseCase implements UpdateAccountUseCaseContract {
  const UpdateAccountUseCase(this._repository);

  final AccountRepositoryContract _repository;

  @override
  Future<AppResult<Account>> call({
    String? fullName,
    String? avatarUrl,
    Visibility? privacy,
    UsageFocus? usageFocus,
    DateTime? birthDate,
    bool clearBirthDate = false,
  }) => _repository.updateAccount(
    fullName: fullName,
    avatarUrl: avatarUrl,
    privacy: privacy,
    usageFocus: usageFocus,
    birthDate: birthDate,
    clearBirthDate: clearBirthDate,
  );
}
