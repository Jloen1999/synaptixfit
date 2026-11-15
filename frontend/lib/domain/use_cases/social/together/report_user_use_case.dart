import '../../../enums/together_enums.dart';
import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Denuncia a una persona desde lo compartido con amigos; va a moderación.
abstract interface class ReportUserUseCaseContract {
  Future<AppResult<Unit>> call(
    String userId, {
    required UserReportContext context,
  });
}

/// Implementa [ReportUserUseCaseContract] con [TogetherRepositoryContract].
class ReportUserUseCase implements ReportUserUseCaseContract {
  const ReportUserUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(
    String userId, {
    required UserReportContext context,
  }) => _repository.reportUser(userId, context: context);
}
