import 'package:go_router/go_router.dart';

import 'analytics/page/analytics_page.dart';
import 'badges/page/badges_page.dart';
import 'overview/page/progress_overview_page.dart';

/// Rutas del módulo progress.
abstract final class ProgressPaths {
  /// Pestaña Progreso (nivel, racha, insignias, analítica, carga y comunidad).
  static const root = '/progress';

  /// Analítica de entrenamiento (pantalla completa).
  static const analytics = '/progress/analytics';

  /// Catálogo de insignias (pantalla completa).
  static const badges = '/progress/badges';
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
    builder: (context, state) => const ProgressOverviewPage(),
  ),
];

/// Rutas a pantalla completa (sin barra inferior).
List<RouteBase> progressRoutes() => [
  GoRoute(
    path: ProgressPaths.analytics,
    builder: (context, state) => const AnalyticsPage(),
  ),
  GoRoute(
    path: ProgressPaths.badges,
    builder: (context, state) => const BadgesPage(),
  ),
];
