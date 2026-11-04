import 'package:get_it/get_it.dart';

import '../../app/config/app_config.dart';
import '../../domain/repositories/account_repository_contract.dart';
import '../../domain/repositories/auth_repository_contract.dart';
import '../../domain/repositories/data_change_repository_contract.dart';
import '../local_data_source/session_drafts_cleaner.dart';
import '../local_data_source/token_storage.dart';
import '../remote_data_source/api/api_client.dart';
import '../remote_data_source/api/data_change_interceptor.dart';
import '../remote_data_source/api/session_expiry_notifier.dart';
import '../remote_data_source/auth/auth_remote_data_source.dart';
import '../remote_data_source/auth/google_auth_data_source.dart';
import '../repository/account_repository.dart';
import '../repository/auth_repository.dart';
import '../repository/data_change_repository.dart';
import 'home_data_di.dart';
import 'academic_data_di.dart';
import 'training_data_di.dart';
import 'challenges_data_di.dart';
import 'progress_data_di.dart';
import 'profile_data_di.dart';
import 'planner_data_di.dart';
import 'social_data_di.dart';
import 'admin_data_di.dart';
import 'reminders_data_di.dart';
import 'wellbeing_data_di.dart';

/// Registra la capa data. Cada módulo registra lo suyo en `<modulo>_data_di.dart`.
void registerData(GetIt getIt, AppConfig config) {
  getIt
    ..registerLazySingleton<TokenStorage>(SecureTokenStorage.new)
    ..registerLazySingleton(SessionExpiryNotifier.new)
    ..registerLazySingleton(DataChangeInterceptor.new)
    ..registerLazySingleton(
      () => ApiClient(
        baseUrl: config.apiBaseUrl,
        tokens: getIt(),
        expiry: getIt(),
        changes: getIt(),
      ),
    )
    ..registerLazySingleton<DataChangeRepositoryContract>(
      () => DataChangeRepository(getIt()),
    )
    ..registerLazySingleton(() => AuthRemoteDataSource(getIt()))
    ..registerLazySingleton(
      () => GoogleAuthDataSource(
        clientId: config.googleClientId,
        serverClientId: config.googleServerClientId,
      ),
    )
    ..registerLazySingleton<AuthRepositoryContract>(
      () => AuthRepository(
        remote: getIt(),
        google: getIt(),
        tokens: getIt(),
        expiry: getIt(),
        drafts: SessionDraftsCleaner(),
      ),
    )
    ..registerLazySingleton<AccountRepositoryContract>(
      () => AccountRepository(getIt()),
    );

  registerHomeData(getIt);
  registerAcademicData(getIt);
  registerTrainingData(getIt);
  registerChallengesData(getIt);
  registerProgressData(getIt);
  registerProfileData(getIt);
  registerPlannerData(getIt);
  registerSocialData(getIt);
  registerAdminData(getIt);
  registerRemindersData(getIt);
  registerWellbeingData(getIt);
}
