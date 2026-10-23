import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/social/dto/friendship_dto.dart';
import 'package:synaptixfit/data/remote_data_source/social/dto/notification_dto.dart';
import 'package:synaptixfit/data/remote_data_source/social/dto/page_dto.dart';
import 'package:synaptixfit/data/remote_data_source/social/dto/post_dto.dart';
import 'package:synaptixfit/data/remote_data_source/social/dto/public_profile_dto.dart';
import 'package:synaptixfit/domain/enums/friendship_relation.dart';
import 'package:synaptixfit/domain/enums/friendship_status.dart';
import 'package:synaptixfit/domain/enums/notification_priority.dart';
import 'package:synaptixfit/domain/enums/notification_type.dart';
import 'package:synaptixfit/domain/enums/post_type.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/social/post_link.dart';

Map<String, dynamic> _postJson({Object? metadata, String? imageUrl}) => {
  'id': 'p1',
  'author': {'id': 'u1', 'fullName': 'Ana', 'avatarUrl': null},
  'type': 'BADGE_UNLOCKED',
  'description': 'Nueva insignia',
  'imageUrl': imageUrl,
  'metadata': metadata,
  'createdAt': '2026-10-01T10:00:00Z',
  'editedAt': null,
  'edited': false,
  'likesCount': 3,
  'commentsCount': 1,
  'likedByMe': true,
  'mine': false,
};

void main() {
  group('PostDto', () {
    test('mapea tipo, contadores y convierte la fecha UTC a local', () {
      final post = PostDto.fromJson(_postJson()).toDomain();

      expect(post.type, PostType.badgeUnlocked);
      expect(post.likesCount, 3);
      expect(post.likedByMe, isTrue);
      expect(post.createdAt.isUtc, isFalse);
      expect(post.createdAt, DateTime.utc(2026, 10, 1, 10).toLocal());
      expect(post.link, isNull);
    });

    test('una imagen vacía se trata como sin imagen', () {
      expect(
        PostDto.fromJson(_postJson(imageUrl: ' ')).toDomain().imageUrl,
        isNull,
      );
    });

    test('lee el enlace de los metadatos con claves nuevas', () {
      final post = PostDto.fromJson(
        _postJson(
          metadata: {
            'entityType': 'ROUTINE',
            'entityId': 'r1',
            'entityName': 'Full body',
          },
        ),
      ).toDomain();

      expect(
        post.link,
        const PostLink(kind: PostLinkKind.routine, id: 'r1', name: 'Full body'),
      );
    });

    test('acepta las claves heredadas de la app antigua', () {
      final link = parsePostLink({
        'entidad_tipo': 'reto',
        'entidad_id': 'c1',
        'entidad_nombre': '10 km',
      });

      expect(
        link,
        const PostLink(kind: PostLinkKind.challenge, id: 'c1', name: '10 km'),
      );
    });

    test('ignora metadatos sin tipo conocido o sin nombre', () {
      expect(parsePostLink({'entityType': 'otro', 'entityName': 'x'}), isNull);
      expect(parsePostLink({'entityType': 'badge'}), isNull);
      expect(parsePostLink('texto'), isNull);
    });
  });

  test('PageDto calcula si hay más páginas', () {
    final page = PageDto<PostDto>.fromJson(
      {
        'items': [_postJson()],
        'page': 0,
        'size': 1,
        'totalItems': 2,
        'totalPages': 2,
      },
      (json) => PostDto.fromJson(json! as Map<String, dynamic>),
    ).toDomain((dto) => dto.toDomain());

    expect(page.items.single.id, 'p1');
    expect(page.hasMore, isTrue);
  });

  test('FriendshipDto mapea estado y relación', () {
    final friendship = FriendshipDto.fromJson({
      'id': 'f1',
      'status': 'PENDING',
      'relation': 'REQUEST_RECEIVED',
      'user': {'id': 'u2', 'fullName': 'Luis', 'level': 4},
      'createdAt': '2026-10-01T10:00:00Z',
      'updatedAt': '2026-10-01T10:00:00Z',
    }).toDomain();

    expect(friendship.status, FriendshipStatus.pending);
    expect(friendship.relation, FriendshipRelation.requestReceived);
    expect(friendship.user.level, 4);
  });

  test(
    'PublicProfileDto oculta las métricas si el perfil está restringido',
    () {
      final profile = PublicProfileDto.fromJson({
        'id': 'u2',
        'fullName': 'Luis',
        'privacy': 'FRIENDS',
        'restricted': true,
        'level': 4,
        'streak': 9,
        'postsCount': 3,
        'friendsCount': 2,
        'relation': 'NONE',
      }).toDomain();

      expect(profile.privacy, Visibility.friends);
      expect(profile.level, 4);
      expect(profile.streak, isNull);
      expect(profile.postsCount, isNull);
      expect(profile.relation, FriendshipRelation.none);
    },
  );

  test('NotificationDto mapea prioridad, tipo y enlace', () {
    final notification = NotificationDto.fromJson({
      'id': 'n1',
      'title': 'Nuevo me gusta',
      'description': 'Ana ha dado me gusta',
      'priority': 'RECOMMENDED',
      'type': 'FATIGUE_ALERT',
      'actionUrl': '/social/posts/p1',
      'actionLabel': 'Ver publicación',
      'read': false,
      'createdAt': '2026-10-01T10:00:00Z',
    }).toDomain();

    expect(notification.priority, NotificationPriority.recommended);
    expect(notification.type, NotificationType.fatigueAlert);
    expect(notification.actionUrl, '/social/posts/p1');
  });
}
