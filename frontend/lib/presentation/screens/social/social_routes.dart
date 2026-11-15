import 'package:go_router/go_router.dart';

import '../../../domain/enums/friendship_list_kind.dart';
import '../../../domain/enums/together_enums.dart';
import 'feed/page/feed_page.dart';
import 'friends/page/friends_page.dart';
import 'notifications/page/notifications_page.dart';
import 'post_detail/page/post_detail_page.dart';
import 'together/challenge_detail/page/friend_challenge_detail_page.dart';
import 'together/challenge_form/page/friend_challenge_form_page.dart';
import 'together/hub/page/together_page.dart';
import 'together/study_invite/page/study_invite_page.dart';
import 'together/study_room/page/study_room_page.dart';
import 'together/workout_detail/page/workout_together_page.dart';
import 'together/workout_invite/page/workout_invite_page.dart';
import 'user_profile/page/user_profile_page.dart';

/// Rutas del módulo social. Los enlaces de las notificaciones sociales usan
/// [post], [friendRequests] y [user].
abstract final class SocialPaths {
  static const root = '/social';
  static const postPattern = '/social/posts/:postId';
  static const friends = '/social/friends';
  static const friendRequests = '/social/friends/requests';

  /// Amigos con la pestaña «Bloqueados» abierta (desde el aviso de bloquear).
  static const blocked = '/social/friends/blocked';
  static const userPattern = '/social/users/:userId';
  static const notifications = '/notifications';

  /// «Con amigos» (ADR 0044): retos, rachas y entrenos con amigos.
  static const together = '/social/together';
  static const togetherNewChallenge = '/social/together/challenges/new';
  static const togetherChallengePattern = '/social/together/challenges/:id';
  static const togetherNewWorkout = '/social/together/workouts/new';
  static const togetherWorkoutPattern = '/social/together/workouts/:id';

  static String togetherChallenge(String id) =>
      '/social/together/challenges/$id';

  static String togetherWorkout(String id) => '/social/together/workouts/$id';

  /// «Estudiar con amigos» (ADR 0045): `length` (SHORT/LONG) y `subject`
  /// opcionales, los que trae el Pomodoro.
  static const togetherNewStudyRoom = '/social/together/study/new';
  static const togetherStudyRoomPattern = '/social/together/study/:id';

  static String togetherStudyRoom(String id) => '/social/together/study/$id';

  static String post(String postId) => '/social/posts/$postId';

  static String user(String userId) => '/social/users/$userId';
}

/// Rutas de otros módulos a las que llevan los enlaces de las notificaciones.
///
/// Se escriben como texto para no depender de los ficheros de otros módulos.
abstract final class SocialExternalPaths {
  /// Raíces de las pestañas de la barra inferior: se abren cambiando de
  /// pestaña (`go`), porque apilarlas encima duplicaría la barra. `/challenges`
  /// y `/progress/badges` son direcciones antiguas que redirigen a Progreso.
  static const tabRoots = {
    '/home',
    '/planner',
    '/academic',
    '/training',
    '/progress',
    '/challenges',
    '/progress/badges',
  };

  /// Apunte compartido (módulo academic).
  static String sharedNote(String noteId) => '/academic/notes/shared/$noteId';

  /// Todos los apuntes que un autor comparte conmigo (módulo academic).
  static String sharedNotesBy(String authorId) => Uri(
    path: '/academic/notes/shared',
    queryParameters: {'authorId': authorId},
  ).toString();

  /// Sesión en vivo (módulo training): «Empezar» de «Entrenamos juntos».
  static String trainingSession(String sessionId) =>
      '/training/sessions/$sessionId';

  /// `true` si [url] es la raíz de una pestaña (sin contar la query).
  static bool isTabRoot(String url) => tabRoots.contains(Uri.parse(url).path);

  /// `true` si [url] vive dentro de una pestaña (una rutina, un ejercicio):
  /// desde el muro, que es pantalla completa, se abre cambiando de pestaña;
  /// apilarla duplicaría el armazón y la pantalla quedaría en negro.
  static bool opensInTab(String url) {
    final path = Uri.parse(url).path;
    return isTabRoot(url) ||
        path.startsWith('/training/routines/') ||
        path.startsWith('/training/exercises/');
  }
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
    path: SocialPaths.blocked,
    builder: (_, _) =>
        const FriendsPage(initialTab: FriendshipListKind.blocked),
  ),
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
  GoRoute(path: SocialPaths.together, builder: (_, _) => const TogetherPage()),
  // «new» antes que «:id» para que no se lea como un id.
  GoRoute(
    path: SocialPaths.togetherNewChallenge,
    builder: (_, _) => const FriendChallengeFormPage(),
  ),
  GoRoute(
    path: SocialPaths.togetherChallengePattern,
    builder: (_, state) =>
        FriendChallengeDetailPage(challengeId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: SocialPaths.togetherNewWorkout,
    builder: (_, state) => WorkoutInvitePage(
      routineId: state.uri.queryParameters['routine'] ?? '',
      dayId: state.uri.queryParameters['day'],
    ),
  ),
  GoRoute(
    path: SocialPaths.togetherWorkoutPattern,
    builder: (_, state) =>
        WorkoutTogetherPage(workoutId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: SocialPaths.togetherNewStudyRoom,
    builder: (_, state) => StudyInvitePage(
      length: switch (state.uri.queryParameters['length']) {
        final String value => StudyRoomLength.fromApi(value),
        null => null,
      },
      subjectId: state.uri.queryParameters['subject'],
    ),
  ),
  GoRoute(
    path: SocialPaths.togetherStudyRoomPattern,
    builder: (_, state) => StudyRoomPage(roomId: state.pathParameters['id']!),
  ),
];
