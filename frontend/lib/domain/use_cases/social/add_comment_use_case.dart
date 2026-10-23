import '../../models/result/app_result.dart';
import '../../models/social/post_comment.dart';
import '../../repositories/social_repository_contract.dart';

/// Comenta una publicación (1-500 caracteres).
abstract interface class AddCommentUseCaseContract {
  Future<AppResult<PostComment>> call({
    required String postId,
    required String text,
  });
}

class AddCommentUseCase implements AddCommentUseCaseContract {
  const AddCommentUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<PostComment>> call({
    required String postId,
    required String text,
  }) => _repository.addComment(postId: postId, text: text);
}
