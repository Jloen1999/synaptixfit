import '../../domain/models/home/home_setup.dart';
import '../../domain/models/home/home_dashboard.dart';
import '../../domain/models/home/home_due_review.dart';
import '../../domain/models/home/home_onboarding_status.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/home_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/home/home_remote_data_source.dart';

class HomeRepository implements HomeRepositoryContract {
  HomeRepository(this._remote);

  final HomeRemoteDataSource _remote;

  @override
  Future<AppResult<HomeDashboard>> getDashboard() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.dashboard()).toDomain(),
      );

  @override
  Future<AppResult<List<HomeDueReview>>> getDueReviews({int limit = 5}) =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.dueReviews(limit)).map((r) => r.toDomain()).toList(),
      );

  @override
  Future<AppResult<int>> getUnreadNotificationsCount() =>
      RepositoryErrorHandler.guard(_remote.unreadCount);

  @override
  Future<AppResult<HomeSetup>> getSetup() =>
      RepositoryErrorHandler.guard(_remote.setup);

  @override
  Future<AppResult<HomeOnboardingStatus>> getOnboardingStatus() =>
      RepositoryErrorHandler.guard(
        () async => HomeOnboardingStatus(
          completed: await _remote.onboardingCompleted(),
        ),
      );
}
