import '../../models/home/home_due_review.dart';
import '../../models/result/app_result.dart';
import '../../repositories/home_repository_contract.dart';

abstract interface class GetHomeDueReviewsUseCaseContract {
  Future<AppResult<List<HomeDueReview>>> call({int limit = 5});
}

class GetHomeDueReviewsUseCase implements GetHomeDueReviewsUseCaseContract {
  const GetHomeDueReviewsUseCase(this._repository);

  final HomeRepositoryContract _repository;

  @override
  Future<AppResult<List<HomeDueReview>>> call({int limit = 5}) =>
      _repository.getDueReviews(limit: limit);
}
