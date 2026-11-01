import 'enrollment_import/page/enrollment_import_page.dart';
import 'package:go_router/go_router.dart';

import 'change_password/page/change_password_page.dart';
import 'degrees/page/degrees_page.dart';
import 'edit_academic/page/edit_academic_page.dart';
import 'edit_account/page/edit_account_page.dart';
import 'edit_wellness/page/edit_wellness_page.dart';
import 'notification_settings/page/notification_settings_page.dart';
import 'onboarding/page/onboarding_page.dart';
import 'profile/page/profile_page.dart';
import 'settings/page/settings_page.dart';
import 'subject_selector/page/subject_selector_page.dart';
import 'wellness_history/page/wellness_history_page.dart';

/// Rutas del módulo profile (todas a pantalla completa, sin barra inferior).
abstract final class ProfilePaths {
  static const root = '/profile';
  static const editAccount = '/profile/account';
  static const editWellness = '/profile/wellness';
  static const wellnessHistory = '/profile/wellness-history';
  static const editAcademic = '/profile/academic';
  static const degrees = '/profile/degrees';
  static const subjects = '/profile/subjects';
  static const enrollmentImport = '/profile/enrollment';
  static const settings = '/profile/settings';
  static const changePassword = '/profile/settings/password';
  static const notifications = '/profile/settings/notifications';
  static const onboarding = '/onboarding';

  /// Rutas de otros módulos a las que navega este.
  static const home = '/home';
  static const adminPanel = '/admin';
  static const friends = '/social/friends';
  static const community = '/social';
  static String publicProfile(String userId) => '/social/users/$userId';
}

/// Rutas a pantalla completa (sin barra inferior).
List<RouteBase> profileRoutes() => [
  GoRoute(
    path: ProfilePaths.root,
    builder: (_, _) => const ProfilePage(),
    routes: [
      GoRoute(path: 'account', builder: (_, _) => const EditAccountPage()),
      GoRoute(path: 'wellness', builder: (_, _) => const EditWellnessPage()),
      GoRoute(
        path: 'wellness-history',
        builder: (_, _) => const WellnessHistoryPage(),
      ),
      GoRoute(path: 'academic', builder: (_, _) => const EditAcademicPage()),
      GoRoute(path: 'degrees', builder: (_, _) => const DegreesPage()),
      GoRoute(
        path: 'enrollment',
        builder: (_, _) => const EnrollmentImportPage(),
      ),
      GoRoute(
        path: 'subjects',
        builder: (_, _) =>
            const SubjectSelectorPage(degreesPath: ProfilePaths.degrees),
      ),
      GoRoute(
        path: 'settings',
        builder: (_, _) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'password',
            builder: (_, _) => const ChangePasswordPage(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (_, _) => const NotificationSettingsPage(),
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: ProfilePaths.onboarding,
    builder: (_, _) => const OnboardingPage(homePath: ProfilePaths.home),
  ),
];
