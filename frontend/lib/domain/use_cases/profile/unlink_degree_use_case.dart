import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Desvincula una carrera.
abstract interface class UnlinkDegreeUseCaseContract {
  Future<AppResult<Unit>> call(String degreeId);
}

class UnlinkDegreeUseCase implements UnlinkDegreeUseCaseContract {
  const UnlinkDegreeUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String degreeId) =>
      _repository.unlinkDegree(degreeId);
}
