import '../../enums/feed_period.dart';
import '../../models/result/app_result.dart';
import '../../models/social/post.dart';
import '../../models/social/social_page.dart';
import '../../repositories/social_repository_contract.dart';

/// Publicaciones visibles del muro (paginadas, con filtro temporal, sondeo con `since` o por autor).
abstract interface class GetFeedUseCaseContract {
  Future<AppResult<SocialPage<Post>>> call({
    FeedPeriod period = FeedPeriod.all,
    DateTime? since,
    String? authorId,
    int page = 0,
    int size = 20,
  });
}

class GetFeedUseCase implements GetFeedUseCaseContract {
  const GetFeedUseCase(this._repository);

  final SocialRepositoryContract _repository;

  @override
  Future<AppResult<SocialPage<Post>>> call({
    FeedPeriod period = FeedPeriod.all,
    DateTime? since,
    String? authorId,
    int page = 0,
    int size = 20,
  }) => _repository.getFeed(
    period: period,
    since: since,
    authorId: authorId,
    page: page,
    size: size,
  );
}
