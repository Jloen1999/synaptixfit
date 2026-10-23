import '../../models/profile/catalog.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Carreras vinculadas al usuario.
abstract interface class GetMyDegreesUseCaseContract {
  Future<AppResult<List<UserDegree>>> call();
}

class GetMyDegreesUseCase implements GetMyDegreesUseCaseContract {
  const GetMyDegreesUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<List<UserDegree>>> call() => _repository.getMyDegrees();
}
