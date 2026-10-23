import '../../domain/models/progress/badge.dart';
import '../../domain/models/progress/community_post_preview.dart';
import '../../domain/models/progress/physical_load.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/progress_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/progress/progress_remote_data_source.dart';

class ProgressRepository implements ProgressRepositoryContract {
  ProgressRepository(this._remote);

  final ProgressRemoteDataSource _remote;

  @override
  Future<AppResult<PhysicalLoad>> getPhysicalLoad() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.physicalLoad()).toDomain(),
      );

  @override
  Future<AppResult<List<CommunityPostPreview>>> getCommunityPreview({
    int size = 3,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.latestPosts(
      size,
    )).items.map((p) => p.toDomain()).toList(),
  );

  @override
  Future<AppResult<Unit>> shareBadge({required Badge badge, String? message}) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.createPost({
          'type': 'BADGE_UNLOCKED',
          // Sin comentario, la publicación muestra la propia insignia.
          'description': message ?? '${badge.icon} ${badge.name}'.trim(),
          'metadata': {
            'badgeId': badge.id,
            'badgeName': badge.name,
            'badgeIcon': badge.icon,
            'rarity': badge.rarity.name.toUpperCase(),
          },
        });
        return unit;
      });
}
