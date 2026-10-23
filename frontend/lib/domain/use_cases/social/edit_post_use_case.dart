import '../../models/result/app_result.dart';
import '../../models/social/post.dart';
import '../../repositories/social_repository_contract.dart';

/// Edita el texto o la imagen de una publicación propia.
abstract interface class EditPostUseCaseContract {
  Future<AppResult<Post>> call({
    required String postId,
    required String description,
    String? imageUrl,
  });
}

class EditPostUseCase implements EditPostUseCaseContract {
  const EditPostUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<Post>> call({
    required String postId,
    required String description,
    String? imageUrl,
  }) => _repository.editPost(
    postId: postId,
    description: description,
    imageUrl: imageUrl,
  );
}
