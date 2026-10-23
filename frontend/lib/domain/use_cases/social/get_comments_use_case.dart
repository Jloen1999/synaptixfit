import '../../models/result/app_result.dart';
import '../../models/social/post_comment.dart';
import '../../models/social/social_page.dart';
import '../../repositories/social_repository_contract.dart';

/// Comentarios de una publicación (del más antiguo al más reciente).
abstract interface class GetCommentsUseCaseContract {
  Future<AppResult<SocialPage<PostComment>>> call({
    required String postId,
    int page = 0,
    int size = 20,
  });
}

class GetCommentsUseCase implements GetCommentsUseCaseContract {
  const GetCommentsUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<SocialPage<PostComment>>> call({
    required String postId,
    int page = 0,
    int size = 20,
  }) => _repository.getComments(postId: postId, page: page, size: size);
}
