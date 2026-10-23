import 'package:get_it/get_it.dart';

import '../../domain/repositories/challenge_references_repository_contract.dart';
import '../../domain/repositories/challenges_repository_contract.dart';
import '../remote_data_source/challenges/challenge_references_remote_data_source.dart';
import '../remote_data_source/challenges/challenges_remote_data_source.dart';
import '../repository/challenge_references_repository.dart';
import '../repository/challenges_repository.dart';

/// Data sources y repositorios del módulo challenges.
void registerChallengesData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => ChallengesRemoteDataSource(getIt()))
    ..registerLazySingleton(() => ChallengeReferencesRemoteDataSource(getIt()))
    ..registerLazySingleton<ChallengesRepositoryContract>(
      () => ChallengesRepository(getIt()),
    )
    ..registerLazySingleton<ChallengeReferencesRepositoryContract>(
      () => ChallengeReferencesRepository(getIt()),
    );
}
