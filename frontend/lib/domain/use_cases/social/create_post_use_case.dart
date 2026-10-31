import '../../enums/post_type.dart';
import '../../models/result/app_result.dart';
import '../../models/social/post.dart';
import '../../repositories/social_repository_contract.dart';

/// Publica en el muro.
abstract interface class CreatePostUseCaseContract {
  /// [metadata]: entidad vinculada (p. ej. `{'sessionId': …}`); con ella el
  /// servidor puede evitar duplicados.
  Future<AppResult<Post>> call({
    required PostType type,
    required String description,
    String? imageUrl,
    Map<String, Object?>? metadata,
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
    Map<String, Object?>? metadata,
  }) => _repository.createPost(
    type: type,
    description: description,
    imageUrl: imageUrl,
    metadata: metadata,
  );
}
