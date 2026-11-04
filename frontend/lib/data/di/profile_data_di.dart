import '../repository/enrollment_repository.dart';
import '../remote_data_source/profile/enrollment_remote_data_source.dart';
import '../../domain/repositories/enrollment_repository_contract.dart';
import 'package:get_it/get_it.dart';

import '../../domain/repositories/device_permissions_repository_contract.dart';
import '../../domain/repositories/legal_repository_contract.dart';
import '../local_data_source/device_permissions_data_source.dart';
import '../remote_data_source/profile/legal_remote_data_source.dart';
import '../repository/device_permissions_repository.dart';
import '../repository/legal_repository.dart';

import '../../domain/repositories/language_repository_contract.dart';
import '../local_data_source/language_storage.dart';
import '../repository/language_repository.dart';
import '../../domain/repositories/appearance_repository_contract.dart';
import '../../domain/repositories/account_privacy_repository_contract.dart';
import '../../domain/repositories/notification_preferences_repository_contract.dart';
import '../../domain/repositories/profile_catalog_repository_contract.dart';
import '../../domain/repositories/profile_repository_contract.dart';
import '../local_data_source/appearance_storage.dart';
import '../local_data_source/data_export_file_saver.dart';
import '../remote_data_source/profile/account_privacy_remote_data_source.dart';
import '../remote_data_source/profile/notification_preferences_remote_data_source.dart';
import '../remote_data_source/profile/profile_catalog_remote_data_source.dart';
import '../remote_data_source/profile/profile_remote_data_source.dart';
import '../repository/appearance_repository.dart';
import '../repository/account_privacy_repository.dart';
import '../repository/notification_preferences_repository.dart';
import '../repository/profile_catalog_repository.dart';
import '../repository/profile_repository.dart';

/// Data sources y repositorios del módulo profile.
void registerProfileData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => ProfileRemoteDataSource(getIt()))
    ..registerLazySingleton(() => ProfileCatalogRemoteDataSource(getIt()))
    ..registerLazySingleton(() => AccountPrivacyRemoteDataSource(getIt()))
    ..registerLazySingleton(
      () => NotificationPreferencesRemoteDataSource(getIt()),
    )
    ..registerLazySingleton(() => const DataExportFileSaver())
    ..registerLazySingleton<AppearanceStorage>(SharedPrefsAppearanceStorage.new)
    ..registerLazySingleton<AppearanceRepositoryContract>(
      () => AppearanceRepository(getIt()),
    )
    ..registerLazySingleton(() => EnrollmentRemoteDataSource(getIt()))
    ..registerLazySingleton<EnrollmentRepositoryContract>(
      () => EnrollmentRepository(getIt()),
    )
    ..registerLazySingleton<LanguageStorage>(SharedPrefsLanguageStorage.new)
    ..registerLazySingleton<LanguageRepositoryContract>(
      () => LanguageRepository(getIt()),
    )
    ..registerLazySingleton<ProfileRepositoryContract>(
      () => ProfileRepository(getIt()),
    )
    ..registerLazySingleton<ProfileCatalogRepositoryContract>(
      () => ProfileCatalogRepository(getIt()),
    )
    ..registerLazySingleton<AccountPrivacyRepositoryContract>(
      () => AccountPrivacyRepository(getIt(), getIt()),
    )
    ..registerLazySingleton<NotificationPreferencesRepositoryContract>(
      () => NotificationPreferencesRepository(getIt()),
    )
    ..registerLazySingleton<DevicePermissionsDataSource>(
      PluginDevicePermissionsDataSource.new,
    )
    ..registerLazySingleton<DevicePermissionsRepositoryContract>(
      () => DevicePermissionsRepository(getIt()),
    )
    ..registerLazySingleton(() => LegalRemoteDataSource(getIt()))
    ..registerLazySingleton<LegalRepositoryContract>(
      () => LegalRepository(getIt()),
    );
}
