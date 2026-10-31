import '../../domain/enums/feed_period.dart';
import '../../domain/enums/post_type.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/social/like_status.dart';
import '../../domain/models/social/post.dart';
import '../../domain/models/social/post_comment.dart';
import '../../domain/models/social/public_profile.dart';
import '../../domain/models/social/social_page.dart';
import '../../domain/models/social/user_card.dart';
import '../../domain/repositories/social_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/social/social_remote_data_source.dart';

class SocialRepository implements SocialRepositoryContract {
  SocialRepository(this._remote);

  final SocialRemoteDataSource _remote;

  @override
  Future<AppResult<SocialPage<Post>>> getFeed({
    FeedPeriod period = FeedPeriod.all,
    DateTime? since,
    String? authorId,
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.feed(
      period: period.apiValue,
      since: since,
      authorId: authorId,
      page: page,
      size: size,
    )).toDomain((dto) => dto.toDomain()),
  );

  @override
  Future<AppResult<Post>> getPost(String postId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.post(postId)).toDomain(),
      );

  @override
  Future<AppResult<Post>> createPost({
    required PostType type,
    required String description,
    String? imageUrl,
    Map<String, Object?>? metadata,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.createPost(
      type: type.apiValue,
      description: description,
      imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
      metadata: metadata,
    )).toDomain(),
  );

  @override
  Future<AppResult<Post>> editPost({
    required String postId,
    required String description,
    String? imageUrl,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.editPost(
      postId,
      description: description,
      imageUrl: imageUrl ?? '',
    )).toDomain(),
  );

  @override
  Future<AppResult<Unit>> deletePost(String postId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deletePost(postId);
        return unit;
      });

  @override
  Future<AppResult<Unit>> reportPost(String postId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.reportPost(postId);
        return unit;
      });

  @override
  Future<AppResult<LikeStatus>> setLike({
    required String postId,
    required bool liked,
  }) => RepositoryErrorHandler.guard(
    () async => (await (liked ? _remote.like(postId) : _remote.unlike(postId)))
        .toDomain(),
  );

  @override
  Future<AppResult<SocialPage<PostComment>>> getComments({
    required String postId,
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.comments(
      postId,
      page: page,
      size: size,
    )).toDomain((dto) => dto.toDomain()),
  );

  @override
  Future<AppResult<PostComment>> addComment({
    required String postId,
    required String text,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.addComment(postId, text)).toDomain(),
  );

  @override
  Future<AppResult<PostComment>> editComment({
    required String commentId,
    required String text,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.editComment(commentId, text)).toDomain(),
  );

  @override
  Future<AppResult<Unit>> deleteComment(String commentId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteComment(commentId);
        return unit;
      });

  @override
  Future<AppResult<Unit>> reportComment(String commentId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.reportComment(commentId);
        return unit;
      });

  @override
  Future<AppResult<SocialPage<UserCard>>> searchUsers({
    required String query,
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.searchUsers(
      query,
      page: page,
      size: size,
    )).toDomain((dto) => dto.toDomain()),
  );

  @override
  Future<AppResult<PublicProfile>> getPublicProfile(String userId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.profile(userId)).toDomain(),
      );
}
