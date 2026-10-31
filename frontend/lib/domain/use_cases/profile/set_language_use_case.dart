import '../../enums/app_language.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/language_repository_contract.dart';

/// Guarda el idioma elegido en este dispositivo.
abstract interface class SetLanguageUseCaseContract {
  Future<AppResult<Unit>> call(AppLanguage language);
}

class SetLanguageUseCase implements SetLanguageUseCaseContract {
  const SetLanguageUseCase(this._repository);

  final LanguageRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(AppLanguage language) =>
      _repository.setLanguage(language);
}
