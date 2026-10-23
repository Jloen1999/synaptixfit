import 'package:go_router/go_router.dart';

import 'dashboard/page/home_dashboard_page.dart';

/// Rutas del módulo home.
abstract final class HomePaths {
  static const root = '/home';
}

/// Rutas dentro de la pestaña (conservan la barra inferior).
List<RouteBase> homeBranchRoutes() => [
  GoRoute(
    path: HomePaths.root,
    builder: (context, state) => const HomeDashboardPage(),
  ),
];

/// Rutas a pantalla completa (sin barra inferior). El inicio no tiene.
List<RouteBase> homeRoutes() => [];
