import 'package:synaptixfit/domain/enums/friendship_list_kind.dart';
import 'package:synaptixfit/domain/enums/friendship_relation.dart';
import 'package:synaptixfit/domain/enums/friendship_status.dart';
import 'package:synaptixfit/domain/enums/notification_priority.dart';
import 'package:synaptixfit/domain/enums/notification_type.dart';
import 'package:synaptixfit/domain/enums/post_type.dart';
import 'package:synaptixfit/domain/models/social/app_notification.dart';
import 'package:synaptixfit/domain/models/social/friendship.dart';
import 'package:synaptixfit/domain/models/social/post.dart';
import 'package:synaptixfit/domain/models/social/post_comment.dart';
import 'package:synaptixfit/domain/models/social/social_page.dart';
import 'package:synaptixfit/domain/models/social/social_user.dart';
import 'package:synaptixfit/domain/models/social/user_card.dart';

final baseDate = DateTime(2026, 10, 1, 12);

const ana = SocialUser(id: 'u1', fullName: 'Ana Pérez', level: 3);
const luis = SocialUser(id: 'u2', fullName: 'Luis Gil', level: 5);

Post post(
  String id, {
  int minutes = 0,
  int likes = 0,
  bool liked = false,
  bool mine = false,
  int comments = 0,
}) => Post(
  id: id,
  author: mine ? ana : luis,
  type: PostType.milestoneReached,
  description: 'Post $id',
  createdAt: baseDate.add(Duration(minutes: minutes)),
  edited: false,
  likesCount: likes,
  commentsCount: comments,
  likedByMe: liked,
  mine: mine,
);

PostComment comment(String id, {bool mine = false}) => PostComment(
  id: id,
  postId: 'p1',
  author: mine ? ana : luis,
  text: 'Comentario $id',
  createdAt: baseDate,
  edited: false,
  mine: mine,
);

Friendship friendship(
  String id, {
  FriendshipRelation relation = FriendshipRelation.friends,
  SocialUser user = luis,
}) => Friendship(
  id: id,
  status: relation == FriendshipRelation.friends
      ? FriendshipStatus.accepted
      : FriendshipStatus.pending,
  relation: relation,
  user: user,
  createdAt: baseDate,
);

UserCard userCard(
  String id, {
  FriendshipRelation relation = FriendshipRelation.none,
  String? friendshipId,
}) => UserCard(
  id: id,
  fullName: 'Usuario $id',
  relation: relation,
  friendshipId: friendshipId,
);

AppNotification notification(String id, {bool read = false}) => AppNotification(
  id: id,
  title: 'Aviso $id',
  priority: NotificationPriority.informative,
  type: NotificationType.social,
  actionUrl: '/social/posts/p1',
  read: read,
  createdAt: baseDate,
);

SocialPage<T> page<T>(List<T> items, {int page = 0, int totalPages = 1}) =>
    SocialPage<T>(
      items: items,
      page: page,
      totalPages: totalPages,
      totalItems: items.length,
    );

/// Tipo de listado → relación de sus elementos (para los tests de amistades).
FriendshipRelation relationOf(FriendshipListKind kind) => switch (kind) {
  FriendshipListKind.friends => FriendshipRelation.friends,
  FriendshipListKind.received => FriendshipRelation.requestReceived,
  FriendshipListKind.sent => FriendshipRelation.requestSent,
  FriendshipListKind.blocked => FriendshipRelation.blocked,
};
