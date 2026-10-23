import '../../models/result/app_result.dart';
import '../../models/social/post.dart';
import '../../repositories/social_repository_contract.dart';

/// Detalle de una publicación.
abstract interface class GetPostUseCaseContract {
  Future<AppResult<Post>> call({required String postId});
}

class GetPostUseCase implements GetPostUseCaseContract {
  const GetPostUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<Post>> call({required String postId}) =>
      _repository.getPost(postId);
}
