import '../enums/feed_period.dart';
import '../enums/post_type.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/social/like_status.dart';
import '../models/social/post.dart';
import '../models/social/post_comment.dart';
import '../models/social/public_profile.dart';
import '../models/social/social_page.dart';
import '../models/social/user_card.dart';

/// Muro social: publicaciones, «me gusta», comentarios, reportes y usuarios.
abstract interface class SocialRepositoryContract {
  /// Publicaciones visibles. Con [since] solo las creadas después (sondeo);
  /// con [authorId] solo las de ese autor.
  Future<AppResult<SocialPage<Post>>> getFeed({
    FeedPeriod period = FeedPeriod.all,
    DateTime? since,
    String? authorId,
    int page = 0,
    int size = 20,
  });

  Future<AppResult<Post>> getPost(String postId);

  Future<AppResult<Post>> createPost({
    required PostType type,
    required String description,
    String? imageUrl,
  });

  Future<AppResult<Post>> editPost({
    required String postId,
    required String description,
    String? imageUrl,
  });

  Future<AppResult<Unit>> deletePost(String postId);

  Future<AppResult<Unit>> reportPost(String postId);

  Future<AppResult<LikeStatus>> setLike({
    required String postId,
    required bool liked,
  });

  Future<AppResult<SocialPage<PostComment>>> getComments({
    required String postId,
    int page = 0,
    int size = 20,
  });

  Future<AppResult<PostComment>> addComment({
    required String postId,
    required String text,
  });

  Future<AppResult<PostComment>> editComment({
    required String commentId,
    required String text,
  });

  Future<AppResult<Unit>> deleteComment(String commentId);

  Future<AppResult<Unit>> reportComment(String commentId);

  Future<AppResult<SocialPage<UserCard>>> searchUsers({
    required String query,
    int page = 0,
    int size = 20,
  });

  Future<AppResult<PublicProfile>> getPublicProfile(String userId);
}
