import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'domain/enums/usage_focus.dart';

import 'presentation/screens/auth/forgot_password/page/forgot_password_page.dart';
import 'presentation/screens/auth/login/page/login_page.dart';
import 'presentation/screens/auth/register/page/register_page.dart';
import 'presentation/screens/auth/reset_password/page/reset_password_page.dart';
import 'presentation/screens/auth/session/bloc/session_bloc.dart';
import 'presentation/screens/shell/page/main_shell_page.dart';
import 'presentation/screens/splash/page/splash_page.dart';
import 'presentation/screens/home/home_routes.dart';
import 'presentation/screens/academic/academic_routes.dart';
import 'presentation/screens/training/training_routes.dart';
import 'presentation/screens/training/widgets/training_section_bar.dart';
import 'presentation/screens/challenges/challenges_routes.dart';
import 'presentation/screens/progress/progress_routes.dart';
import 'presentation/screens/profile/legal/bloc/legal_acceptance_bloc.dart';
import 'presentation/screens/profile/legal/page/legal_acceptance_page.dart';
import 'presentation/screens/profile/profile_routes.dart';
import 'presentation/screens/planner/planner_routes.dart';
import 'presentation/screens/social/social_routes.dart';
import 'presentation/screens/admin/admin_routes.dart';

/// Navegación de la app. Cada módulo declara sus rutas en `<modulo>_routes.dart`.
GoRouter buildRouter(SessionBloc session, LegalAcceptanceBloc legal) {
  const publicPaths = {
    LoginPage.path,
    RegisterPage.path,
    ForgotPasswordPage.path,
  };
  return GoRouter(
    initialLocation: SplashPage.path,
    refreshListenable: Listenable.merge([
      _StreamListenable(session.stream),
      _StreamListenable(legal.stream),
    ]),
    redirect: (context, state) {
      final location = state.matchedLocation;
      // El enlace del correo funciona con o sin sesión y no puede pasar por la
      // pantalla de carga: se perdería el token de la dirección.
      if (location == ResetPasswordPage.path) return null;
      // Política de privacidad y condiciones: se leen con o sin sesión (el
      // registro enlaza a ellas antes de crear la cuenta).
      if (location.startsWith(ProfilePaths.legalPrefix)) return null;
      return switch (session.state) {
        SessionUnknown() =>
          location == SplashPage.path ? null : SplashPage.path,
        SessionUnauthenticated() =>
          publicPaths.contains(location) ? null : LoginPage.path,
        // Sin aceptar la versión vigente de la política no se entra en nada
        // más, tampoco en el onboarding ni en los permisos (ADR 0034).
        SessionAuthenticatedState()
            when legal.state.status == LegalGateStatus.required =>
          location == LegalAcceptancePage.path
              ? null
              : LegalAcceptancePage.path,
        SessionAuthenticatedState(:final account) =>
          publicPaths.contains(location) ||
                  location == SplashPage.path ||
                  location == LegalAcceptancePage.path ||
                  _hiddenByFocus(location, account.usageFocus)
              ? HomePaths.root
              : null,
      };
    },
    routes: [
      GoRoute(path: SplashPage.path, builder: (_, _) => const SplashPage()),
      GoRoute(path: LoginPage.path, builder: (_, _) => const LoginPage()),
      GoRoute(path: RegisterPage.path, builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: ForgotPasswordPage.path,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: ResetPasswordPage.path,
        builder: (_, state) =>
            ResetPasswordPage(token: state.uri.queryParameters['token'] ?? ''),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShellPage(
          shell: shell,
          // En Entreno › Gimnasio, la tarjeta del día ya lleva «Continuar»: un
          // solo camino a la sesión abierta de una rutina (ADR 0039).
          onGym:
              state.uri.path == TrainingPaths.root &&
              TrainingSection.fromQuery(state.uri.queryParameters['section']) ==
                  TrainingSection.gym,
        ),
        // Mismo orden que la barra: Inicio · Calendario · Académico · Entreno
        // · Progreso (ADR 0038). Los retos viven dentro de Progreso.
        branches: [
          StatefulShellBranch(routes: homeBranchRoutes()),
          StatefulShellBranch(routes: plannerBranchRoutes()),
          StatefulShellBranch(routes: academicBranchRoutes()),
          StatefulShellBranch(routes: trainingBranchRoutes()),
          StatefulShellBranch(routes: progressBranchRoutes()),
        ],
      ),
      ...homeRoutes(),
      ...academicRoutes(),
      ...trainingRoutes(),
      ...challengesRoutes(),
      ...progressRoutes(),
      ...profileRoutes(),
      ...plannerRoutes(),
      ...socialRoutes(),
      ...adminRoutes(),
    ],
  );
}

/// Rutas del ámbito que la persona no usa: con solo deporte, lo académico;
/// con solo estudios, las rutinas. El calendario sigue abierto a todos (también
/// planifica entrenamientos y descansos).
bool _hiddenByFocus(String location, UsageFocus focus) =>
    (!focus.includesAcademic && location.startsWith('/academic')) ||
    (!focus.includesFitness && location.startsWith('/training'));

/// Adapta un Stream a Listenable para que GoRouter reevalúe las redirecciones.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
