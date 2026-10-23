import '../../models/result/app_result.dart';
import '../../models/social/like_status.dart';
import '../../repositories/social_repository_contract.dart';

/// Da o quita el «me gusta» de una publicación.
abstract interface class SetPostLikeUseCaseContract {
  Future<AppResult<LikeStatus>> call({
    required String postId,
    required bool liked,
  });
}

class SetPostLikeUseCase implements SetPostLikeUseCaseContract {
  const SetPostLikeUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<LikeStatus>> call({
    required String postId,
    required bool liked,
  }) => _repository.setLike(postId: postId, liked: liked);
}
