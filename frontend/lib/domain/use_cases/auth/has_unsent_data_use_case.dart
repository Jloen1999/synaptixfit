import '../../models/result/app_result.dart';
import '../../repositories/auth_repository_contract.dart';

/// ¿Se perdería algo al cerrar sesión? Ajustes solo confirma «Cerrar sesión»
/// si es así (vocabulario §4: lo que no tiene vuelta atrás se confirma).
abstract interface class HasUnsentDataUseCaseContract {
  Future<AppResult<bool>> call();
}

class HasUnsentDataUseCase implements HasUnsentDataUseCaseContract {
  const HasUnsentDataUseCase(this._repository);

  final AuthRepositoryContract _repository;

  @override
  Future<AppResult<bool>> call() => _repository.hasUnsentData();
}
