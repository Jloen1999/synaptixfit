import '../../domain/enums/badge_category.dart';
import '../../domain/models/progress/badge.dart';
import '../../domain/models/progress/streak.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/badge_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/progress/badge_remote_data_source.dart';

/// Implementa [BadgeRepositoryContract] con [BadgeRemoteDataSource].
class BadgeRepository implements BadgeRepositoryContract {
  BadgeRepository(this._remote);

  final BadgeRemoteDataSource _remote;

  @override
  Future<AppResult<List<Badge>>> getCatalog({BadgeCategory? category}) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.catalog(
          category: category?.apiValue,
        )).map((b) => b.toDomain()).toList(),
      );

  @override
  Future<AppResult<List<Badge>>> getMine({bool includeHidden = false}) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.mine(
          includeHidden: includeHidden,
        )).map((b) => b.toDomain()).toList(),
      );

  @override
  Future<AppResult<Badge>> changeVisibility({
    required String badgeId,
    required bool visible,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.changeVisibility(badgeId, visible)).toDomain(),
  );

  @override
  Future<AppResult<List<Badge>>> getUnnotified() =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.unnotified()).map((b) => b.toDomain()).toList(),
      );

  @override
  Future<AppResult<Unit>> markNotified(List<String> badgeIds) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.markNotified(badgeIds);
        return unit;
      });

  @override
  Future<AppResult<Streak>> getStreak() => RepositoryErrorHandler.guard(
    () async => (await _remote.streak()).toDomain(),
  );
}
