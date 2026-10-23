import '../../enums/post_type.dart';
import '../../models/result/app_result.dart';
import '../../models/social/post.dart';
import '../../repositories/social_repository_contract.dart';

/// Publica en el muro.
abstract interface class CreatePostUseCaseContract {
  Future<AppResult<Post>> call({
    required PostType type,
    required String description,
    String? imageUrl,
  });
}

class CreatePostUseCase implements CreatePostUseCaseContract {
  const CreatePostUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<Post>> call({
    required PostType type,
    required String description,
    String? imageUrl,
  }) => _repository.createPost(
    type: type,
    description: description,
    imageUrl: imageUrl,
  );
}
