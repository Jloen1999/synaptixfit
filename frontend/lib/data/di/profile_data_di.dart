import 'package:get_it/get_it.dart';

import '../../domain/repositories/account_privacy_repository_contract.dart';
import '../../domain/repositories/notification_preferences_repository_contract.dart';
import '../../domain/repositories/profile_catalog_repository_contract.dart';
import '../../domain/repositories/profile_repository_contract.dart';
import '../local_data_source/data_export_file_saver.dart';
import '../remote_data_source/profile/account_privacy_remote_data_source.dart';
import '../remote_data_source/profile/notification_preferences_remote_data_source.dart';
import '../remote_data_source/profile/profile_catalog_remote_data_source.dart';
import '../remote_data_source/profile/profile_remote_data_source.dart';
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
    );
}
