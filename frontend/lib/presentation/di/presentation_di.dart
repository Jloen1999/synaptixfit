import 'package:get_it/get_it.dart';

import '../screens/auth/login/bloc/login_bloc.dart';
import '../screens/auth/register/bloc/register_bloc.dart';
import '../screens/auth/session/bloc/session_bloc.dart';
import '../screens/auth/forgot_password/bloc/forgot_password_bloc.dart';
import '../screens/auth/reset_password/bloc/reset_password_bloc.dart';
import '../screens/shell/bloc/achievements_bloc.dart';
import 'home_presentation_di.dart';
import 'academic_presentation_di.dart';
import 'training_presentation_di.dart';
import 'challenges_presentation_di.dart';
import 'progress_presentation_di.dart';
import 'profile_presentation_di.dart';
import 'planner_presentation_di.dart';
import 'social_presentation_di.dart';
import 'admin_presentation_di.dart';
import 'reminders_presentation_di.dart';
import 'wellbeing_presentation_di.dart';

/// Registra los blocs. Los de pantalla como factory; la sesión es única.
void registerPresentation(GetIt getIt) {
  getIt
    ..registerLazySingleton(
      () => SessionBloc(
        restoreSession: getIt(),
        logout: getIt(),
        watchSessionExpired: getIt(),
      ),
    )
    ..registerFactory(() => LoginBloc(login: getIt(), loginWithGoogle: getIt()))
    ..registerFactory(() => ForgotPasswordBloc(requestReset: getIt()))
    ..registerFactory(() => ResetPasswordBloc(resetPassword: getIt()))
    ..registerFactory(() => RegisterBloc(register: getIt()))
    ..registerFactory(
      () => AchievementsBloc(
        getAccount: getIt(),
        checkNewBadges: getIt(),
        markBadgesNotified: getIt(),
        watchChanges: getIt(),
      ),
    );

  registerHomePresentation(getIt);
  registerAcademicPresentation(getIt);
  registerTrainingPresentation(getIt);
  registerChallengesPresentation(getIt);
  registerProgressPresentation(getIt);
  registerProfilePresentation(getIt);
  registerPlannerPresentation(getIt);
  registerSocialPresentation(getIt);
  registerAdminPresentation(getIt);
  registerRemindersPresentation(getIt);
  registerWellbeingPresentation(getIt);
}
