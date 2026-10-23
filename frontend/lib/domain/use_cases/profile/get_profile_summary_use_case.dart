import '../../models/profile/profile_summary.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Resumen del perfil (físico, académico, carreras y onboarding).
abstract interface class GetProfileSummaryUseCaseContract {
  Future<AppResult<ProfileSummary>> call();
}

class GetProfileSummaryUseCase implements GetProfileSummaryUseCaseContract {
  const GetProfileSummaryUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<ProfileSummary>> call() => _repository.getSummary();
}
