import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/social_repository_contract.dart';

/// Borra una publicación propia.
abstract interface class DeletePostUseCaseContract {
  Future<AppResult<Unit>> call({required String postId});
}

class DeletePostUseCase implements DeletePostUseCaseContract {
  const DeletePostUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required String postId}) =>
      _repository.deletePost(postId);
}
