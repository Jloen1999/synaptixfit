import '../../models/result/app_result.dart';
import '../../models/social/social_page.dart';
import '../../models/social/user_card.dart';
import '../../repositories/social_repository_contract.dart';

/// Busca usuarios por nombre con su relación conmigo.
abstract interface class SearchUsersUseCaseContract {
  Future<AppResult<SocialPage<UserCard>>> call({
    required String query,
    int page = 0,
    int size = 20,
  });
}

class SearchUsersUseCase implements SearchUsersUseCaseContract {
  const SearchUsersUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<SocialPage<UserCard>>> call({
    required String query,
    int page = 0,
    int size = 20,
  }) => _repository.searchUsers(query: query, page: page, size: size);
}
