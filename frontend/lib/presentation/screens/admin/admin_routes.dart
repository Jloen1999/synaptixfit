import 'package:go_router/go_router.dart';

import '../../../app/di/app_di.dart';
import '../auth/session/bloc/session_bloc.dart';
import '../home/home_routes.dart';
import 'exercise_form/page/admin_exercise_form_page.dart';
import 'hub/page/admin_hub_page.dart';
import 'user_detail/page/admin_user_detail_page.dart';

/// Rutas del módulo admin. Solo accesibles para cuentas con rol ADMIN.
abstract final class AdminPaths {
  static const root = '/admin';
  static const exerciseNew = '/admin/exercises/new';

  static String userDetail(String userId) => '/admin/users/$userId';

  static String exerciseEdit(String exerciseId) =>
      '/admin/exercises/$exerciseId/edit';
}

/// Rutas a pantalla completa (sin barra inferior). La redirección de la ruta
/// raíz protege también todas sus subrutas.
List<RouteBase> adminRoutes() => [
  GoRoute(
    path: AdminPaths.root,
    redirect: (_, _) =>
        getIt<SessionBloc>().account?.isAdmin == true ? null : HomePaths.root,
    builder: (_, _) => const AdminHubPage(),
    routes: [
      GoRoute(
        path: 'users/:userId',
        builder: (_, state) =>
            AdminUserDetailPage(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: 'exercises/new',
        builder: (_, _) => const AdminExerciseFormPage(),
      ),
      GoRoute(
        path: 'exercises/:exerciseId/edit',
        builder: (_, state) => AdminExerciseFormPage(
          exerciseId: state.pathParameters['exerciseId'],
        ),
      ),
    ],
  ),
];
