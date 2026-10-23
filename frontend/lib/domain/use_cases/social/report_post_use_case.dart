import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/social_repository_contract.dart';

/// Reporta una publicación ajena a moderación.
abstract interface class ReportPostUseCaseContract {
  Future<AppResult<Unit>> call({required String postId});
}

class ReportPostUseCase implements ReportPostUseCaseContract {
  const ReportPostUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required String postId}) =>
      _repository.reportPost(postId);
}
