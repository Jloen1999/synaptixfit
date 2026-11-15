import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Lo que tengo «Con amigos»: invitaciones, retos, rachas y entrenos de hoy.
abstract interface class GetTogetherOverviewUseCaseContract {
  Future<AppResult<TogetherOverview>> call();
}

/// Implementa [GetTogetherOverviewUseCaseContract] con [TogetherRepositoryContract].
class GetTogetherOverviewUseCase implements GetTogetherOverviewUseCaseContract {
  const GetTogetherOverviewUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<TogetherOverview>> call() => _repository.overview();
}
