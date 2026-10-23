import '../../models/result/app_result.dart';
import '../../models/social/post_comment.dart';
import '../../repositories/social_repository_contract.dart';

/// Edita un comentario propio.
abstract interface class EditCommentUseCaseContract {
  Future<AppResult<PostComment>> call({
    required String commentId,
    required String text,
  });
}

class EditCommentUseCase implements EditCommentUseCaseContract {
  const EditCommentUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<PostComment>> call({
    required String commentId,
    required String text,
  }) => _repository.editComment(commentId: commentId, text: text);
}
