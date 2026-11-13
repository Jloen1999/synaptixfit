import 'package:go_router/go_router.dart';

import 'analytics/page/analytics_page.dart';
import 'overview/page/progress_overview_page.dart';

/// Rutas del módulo progress.
abstract final class ProgressPaths {
  /// Pestaña Progreso: «Resumen», «Retos» e «Insignias» (`?tab=`). Se abre con
  /// `go`.
  static const root = '/progress';

  /// Progreso › Retos (pestaña: con `go`).
  static const challenges = '$root?tab=${ProgressTab.challengesKey}';

  /// Progreso › Insignias (pestaña: con `go`).
  static const badgesTab = '$root?tab=${ProgressTab.badgesKey}';

  /// Analítica de entrenamiento (pantalla completa).
  static const analytics = '/progress/analytics';

  /// Dirección antigua del catálogo de insignias (avisos, publicaciones y
  /// apps viejas): lleva a Progreso › Insignias.
  static const badges = '/progress/badges';
}

/// Apartados de la pestaña Progreso y su valor en `?tab=`.
enum ProgressTab {
  summary,
  challenges,
  badges;

  static const challengesKey = 'challenges';
  static const badgesKey = 'badges';

  static ProgressTab fromQuery(String? value) => switch (value) {
    challengesKey => ProgressTab.challenges,
    badgesKey => ProgressTab.badges,
    _ => ProgressTab.summary,
  };
}

/// Rutas de otros módulos a las que navega Progreso (mapa de rutas compartido).
abstract final class ProgressExternalPaths {
  static const socialWall = '/social';
  static String socialPost(String postId) => '/social/posts/$postId';
  static const training = '/training';
  static const pomodoro = '/planner/pomodoro';
  static const academic = '/academic';
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

/// Rutas a pantalla completa (sin barra inferior) y la dirección antigua de
/// las insignias, que ahora son un apartado de la pestaña.
List<RouteBase> progressRoutes() => [
  GoRoute(
    path: ProgressPaths.analytics,
    builder: (context, state) => const AnalyticsPage(),
  ),
  GoRoute(
    path: ProgressPaths.badges,
    redirect: (_, _) => ProgressPaths.badgesTab,
  ),
];
