import 'package:get_it/get_it.dart';

import '../use_cases/auth/login_use_case.dart';
import '../use_cases/auth/register_use_case.dart';
import '../use_cases/auth/login_with_google_use_case.dart';
import '../use_cases/auth/logout_use_case.dart';
import '../use_cases/auth/restore_session_use_case.dart';
import '../use_cases/auth/watch_session_expired_use_case.dart';
import '../use_cases/auth/request_password_reset_use_case.dart';
import '../use_cases/auth/reset_password_use_case.dart';
import '../use_cases/account/get_account_use_case.dart';
import '../use_cases/account/update_account_use_case.dart';
import '../use_cases/account/change_password_use_case.dart';
import '../use_cases/sync/watch_data_changes_use_case.dart';
import 'home_domain_di.dart';
import 'academic_domain_di.dart';
import 'training_domain_di.dart';
import 'challenges_domain_di.dart';
import 'progress_domain_di.dart';
import 'profile_domain_di.dart';
import 'planner_domain_di.dart';
import 'social_domain_di.dart';
import 'admin_domain_di.dart';
import 'reminders_domain_di.dart';

/// Registra los casos de uso. Cada módulo registra los suyos en `<modulo>_domain_di.dart`.
void registerDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<LoginUseCaseContract>(() => LoginUseCase(getIt()))
    ..registerLazySingleton<RegisterUseCaseContract>(
      () => RegisterUseCase(getIt()),
    )
    ..registerLazySingleton<LoginWithGoogleUseCaseContract>(
      () => LoginWithGoogleUseCase(getIt()),
    )
    ..registerLazySingleton<LogoutUseCaseContract>(() => LogoutUseCase(getIt()))
    ..registerLazySingleton<RequestPasswordResetUseCaseContract>(
      () => RequestPasswordResetUseCase(getIt()),
    )
    ..registerLazySingleton<ResetPasswordUseCaseContract>(
      () => ResetPasswordUseCase(getIt()),
    )
    ..registerLazySingleton<RestoreSessionUseCaseContract>(
      () => RestoreSessionUseCase(getIt()),
    )
    ..registerLazySingleton<WatchSessionExpiredUseCaseContract>(
      () => WatchSessionExpiredUseCase(getIt()),
    )
    ..registerLazySingleton<GetAccountUseCaseContract>(
      () => GetAccountUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateAccountUseCaseContract>(
      () => UpdateAccountUseCase(getIt()),
    )
    ..registerLazySingleton<ChangePasswordUseCaseContract>(
      () => ChangePasswordUseCase(getIt()),
    )
    ..registerLazySingleton<WatchDataChangesUseCaseContract>(
      () => WatchDataChangesUseCase(getIt()),
    );

  registerHomeDomain(getIt);
  registerAcademicDomain(getIt);
  registerTrainingDomain(getIt);
  registerChallengesDomain(getIt);
  registerProgressDomain(getIt);
  registerProfileDomain(getIt);
  registerPlannerDomain(getIt);
  registerSocialDomain(getIt);
  registerAdminDomain(getIt);
  registerRemindersDomain(getIt);
}
