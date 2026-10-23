import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/social_repository_contract.dart';

/// Borra un comentario propio.
abstract interface class DeleteCommentUseCaseContract {
  Future<AppResult<Unit>> call({required String commentId});
}

class DeleteCommentUseCase implements DeleteCommentUseCaseContract {
  const DeleteCommentUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required String commentId}) =>
      _repository.deleteComment(commentId);
}
