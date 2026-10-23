import 'package:get_it/get_it.dart';

import '../../domain/repositories/friendship_repository_contract.dart';
import '../../domain/repositories/notification_repository_contract.dart';
import '../../domain/repositories/social_repository_contract.dart';
import '../remote_data_source/social/notification_remote_data_source.dart';
import '../remote_data_source/social/social_remote_data_source.dart';
import '../repository/friendship_repository.dart';
import '../repository/notification_repository.dart';
import '../repository/social_repository.dart';

/// Data sources y repositorios del módulo social.
void registerSocialData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => SocialRemoteDataSource(getIt()))
    ..registerLazySingleton(() => NotificationRemoteDataSource(getIt()))
    ..registerLazySingleton<SocialRepositoryContract>(
      () => SocialRepository(getIt()),
    )
    ..registerLazySingleton<FriendshipRepositoryContract>(
      () => FriendshipRepository(getIt()),
    )
    ..registerLazySingleton<NotificationRepositoryContract>(
      () => NotificationRepository(getIt()),
    );
}
