import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/social_repository_contract.dart';

/// Reporta un comentario ajeno a moderación.
abstract interface class ReportCommentUseCaseContract {
  Future<AppResult<Unit>> call({required String commentId});
}

class ReportCommentUseCase implements ReportCommentUseCaseContract {
  const ReportCommentUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required String commentId}) =>
      _repository.reportComment(commentId);
}
