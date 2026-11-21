import 'package:go_router/go_router.dart';

import 'analytics/page/analytics_page.dart';
import 'overview/page/progress_overview_page.dart';

/// Rutas del módulo progress: la pestaña «Tú» (antes «Progreso», ADR 0061).
abstract final class ProgressPaths {
  /// Pestaña «Tú»: «Resumen», «Retos», «Insignias» y «Comunidad» (`?tab=`).
  /// Se abre con `go`.
  static const root = '/progress';

  /// Tú › Retos (pestaña: con `go`).
  static const challenges = '$root?tab=${ProgressTab.challengesKey}';

  /// Tú › Insignias (pestaña: con `go`).
  static const badgesTab = '$root?tab=${ProgressTab.badgesKey}';

  /// Tú › Comunidad (pestaña: con `go`): solicitudes, amigos, muro y lo que
  /// se hace con amigos (ADR 0061).
  static const community = '$root?tab=${ProgressTab.communityKey}';

  /// Analítica de entrenamiento (pantalla completa).
  static const analytics = '/progress/analytics';

  /// Dirección antigua del catálogo de insignias (avisos, publicaciones y
  /// apps viejas): lleva a Tú › Insignias.
  static const badges = '/progress/badges';

  /// Dirección corta de Tú › Comunidad para enlaces nuevos (y por si alguien
  /// la escribe): lleva a [community].
  static const communityShortcut = '/community';
}

/// Apartados de la pestaña «Tú» y su valor en `?tab=`.
enum ProgressTab {
  summary,
  challenges,
  badges,
  community;

  static const challengesKey = 'challenges';
  static const badgesKey = 'badges';
  static const communityKey = 'community';

  static ProgressTab fromQuery(String? value) => switch (value) {
    challengesKey => ProgressTab.challenges,
    badgesKey => ProgressTab.badges,
    communityKey => ProgressTab.community,
    _ => ProgressTab.summary,
  };

  /// Dirección del apartado (con `go`).
  String get path => switch (this) {
    ProgressTab.summary => ProgressPaths.root,
    ProgressTab.challenges => ProgressPaths.challenges,
    ProgressTab.badges => ProgressPaths.badgesTab,
    ProgressTab.community => ProgressPaths.community,
  };
}

/// Rutas de otros módulos a las que navega Progreso (mapa de rutas compartido).
abstract final class ProgressExternalPaths {
  /// Perfil (pantalla completa, con `push`): lo abre la cabecera de «Tú».
  static const profile = '/profile';
  static const socialWall = '/social';
  static String socialPost(String postId) => '/social/posts/$postId';
  static const friends = '/social/friends';
  static const friendRequests = '/social/friends/requests';

  /// Amigos con el buscador de personas ya enfocado.
  static const friendSearch = '/social/friends/search';
  static const together = '/social/together';
  static const communityChallenges = '/challenges/community';
  static String user(String userId) => '/social/users/$userId';
  static String togetherChallenge(String id) =>
      '/social/together/challenges/$id';
  static String togetherWorkout(String id) => '/social/together/workouts/$id';
  static String togetherStudyRoom(String id) => '/social/together/study/$id';
  static const training = '/training';
  static const pomodoro = '/planner/pomodoro';

  /// Repaso de [first] seguido de [rest] (la cola de «Repasar todos»).
  static String review(String first, Iterable<String> rest) =>
      '/academic/materials/$first/review'
      '${rest.isEmpty ? '' : '?queue=${rest.join(',')}'}';

  /// Calendario con «Añadir al calendario» abierto en el próximo hueco.
  static String addEvent([DateTime? now]) => Uri(
    path: '/planner',
    queryParameters: {
      'new': '${(now ?? DateTime.now()).millisecondsSinceEpoch}',
    },
  ).toString();
}

/// Rutas dentro de la pestaña (conservan la barra inferior).
List<RouteBase> progressBranchRoutes() => [
  GoRoute(
    path: ProgressPaths.root,
    builder: (context, state) => ProgressOverviewPage(
      tab: ProgressTab.fromQuery(state.uri.queryParameters['tab']),
    ),
  ),
];

/// Rutas a pantalla completa (sin barra inferior) y las direcciones que
/// llevan a un apartado de la pestaña (insignias antiguas y `/community`).
List<RouteBase> progressRoutes() => [
  GoRoute(
    path: ProgressPaths.analytics,
    builder: (context, state) => const AnalyticsPage(),
  ),
  GoRoute(
    path: ProgressPaths.badges,
    redirect: (_, _) => ProgressPaths.badgesTab,
  ),
  GoRoute(
    path: ProgressPaths.communityShortcut,
    redirect: (_, _) => ProgressPaths.community,
  ),
];
