import '../../enums/app_language.dart';
import '../../models/result/app_result.dart';
import '../../repositories/language_repository_contract.dart';

/// Idioma elegido en este dispositivo (el del dispositivo por defecto).
abstract interface class GetLanguageUseCaseContract {
  Future<AppResult<AppLanguage>> call();
}

class GetLanguageUseCase implements GetLanguageUseCaseContract {
  const GetLanguageUseCase(this._repository);

  final LanguageRepositoryContract _repository;

  @override
  Future<AppResult<AppLanguage>> call() => _repository.getLanguage();
}
