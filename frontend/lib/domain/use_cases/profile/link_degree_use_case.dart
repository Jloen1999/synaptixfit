import '../../models/profile/catalog.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Vincula una carrera del catálogo.
abstract interface class LinkDegreeUseCaseContract {
  Future<AppResult<UserDegree>> call(String degreeId);
}

class LinkDegreeUseCase implements LinkDegreeUseCaseContract {
  const LinkDegreeUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<UserDegree>> call(String degreeId) =>
      _repository.linkDegree(degreeId);
}
