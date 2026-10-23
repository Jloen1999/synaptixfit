import 'package:go_router/go_router.dart';

import '../../../domain/enums/friendship_list_kind.dart';
import 'feed/page/feed_page.dart';
import 'friends/page/friends_page.dart';
import 'notifications/page/notifications_page.dart';
import 'post_detail/page/post_detail_page.dart';
import 'user_profile/page/user_profile_page.dart';

/// Rutas del módulo social. Los enlaces de las notificaciones sociales usan
/// [post], [friendRequests] y [user].
abstract final class SocialPaths {
  static const root = '/social';
  static const postPattern = '/social/posts/:postId';
  static const friends = '/social/friends';
  static const friendRequests = '/social/friends/requests';
  static const userPattern = '/social/users/:userId';
  static const notifications = '/notifications';

  static String post(String postId) => '/social/posts/$postId';

  static String user(String userId) => '/social/users/$userId';
}

/// Rutas de otros módulos a las que llevan los enlaces de las notificaciones.
///
/// Se escriben como texto para no depender de los ficheros de otros módulos.
abstract final class SocialExternalPaths {
  /// Raíces de las pestañas de la barra inferior: se abren cambiando de
  /// pestaña (`go`), porque apilarlas encima duplicaría la barra.
  static const tabRoots = {
    '/home',
    '/academic',
    '/training',
    '/challenges',
    '/progress',
  };

  /// `true` si [url] es la raíz de una pestaña (sin contar la query).
  static bool isTabRoot(String url) => tabRoots.contains(Uri.parse(url).path);
}

/// Rutas a pantalla completa (sin barra inferior). El módulo no tiene pestaña.
List<RouteBase> socialRoutes() => [
  GoRoute(path: SocialPaths.root, builder: (_, _) => const FeedPage()),
  GoRoute(
    path: SocialPaths.postPattern,
    builder: (_, state) =>
        PostDetailPage(postId: state.pathParameters['postId']!),
  ),
  GoRoute(path: SocialPaths.friends, builder: (_, _) => const FriendsPage()),
  GoRoute(
    path: SocialPaths.friendRequests,
    builder: (_, _) =>
        const FriendsPage(initialTab: FriendshipListKind.received),
  ),
  GoRoute(
    path: SocialPaths.userPattern,
    builder: (_, state) =>
        UserProfilePage(userId: state.pathParameters['userId']!),
  ),
  GoRoute(
    path: SocialPaths.notifications,
    builder: (_, _) => const NotificationsPage(),
  ),
];
