import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Topes de amigos y rondas de «Con amigos» (los manda el servidor).
abstract interface class GetTogetherLimitsUseCaseContract {
  Future<AppResult<TogetherLimits>> call();
}

/// Implementa [GetTogetherLimitsUseCaseContract] con [TogetherRepositoryContract].
class GetTogetherLimitsUseCase implements GetTogetherLimitsUseCaseContract {
  const GetTogetherLimitsUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<TogetherLimits>> call() => _repository.limits();
}
