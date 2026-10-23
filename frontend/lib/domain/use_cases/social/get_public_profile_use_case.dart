import '../../models/result/app_result.dart';
import '../../models/social/public_profile.dart';
import '../../repositories/social_repository_contract.dart';

/// Perfil público de otro usuario.
abstract interface class GetPublicProfileUseCaseContract {
  Future<AppResult<PublicProfile>> call({required String userId});
}

class GetPublicProfileUseCase implements GetPublicProfileUseCaseContract {
  const GetPublicProfileUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<PublicProfile>> call({required String userId}) =>
      _repository.getPublicProfile(userId);
}
