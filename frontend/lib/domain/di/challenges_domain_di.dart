import 'package:get_it/get_it.dart';

import '../use_cases/challenges/clone_challenge_use_case.dart';
import '../use_cases/challenges/create_challenge_use_case.dart';
import '../use_cases/challenges/delete_challenge_use_case.dart';
import '../use_cases/challenges/get_challenge_file_url_use_case.dart';
import '../use_cases/challenges/get_challenge_summary_use_case.dart';
import '../use_cases/challenges/get_challenge_use_case.dart';
import '../use_cases/challenges/list_challenge_attachments_use_case.dart';
import '../use_cases/challenges/list_challenge_link_targets_use_case.dart';
import '../use_cases/challenges/list_challenge_progress_use_case.dart';
import '../use_cases/challenges/list_challenge_subjects_use_case.dart';
import '../use_cases/challenges/list_community_challenges_use_case.dart';
import '../use_cases/challenges/list_my_challenges_use_case.dart';
import '../use_cases/challenges/list_pending_milestones_use_case.dart';
import '../use_cases/challenges/record_challenge_progress_use_case.dart';
import '../use_cases/challenges/reorder_milestones_use_case.dart';
import '../use_cases/challenges/replace_milestones_use_case.dart';
import '../use_cases/challenges/set_challenge_completion_use_case.dart';
import '../use_cases/challenges/set_milestone_completion_use_case.dart';
import '../use_cases/challenges/update_challenge_use_case.dart';

/// Casos de uso del módulo challenges.
void registerChallengesDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<ListMyChallengesUseCaseContract>(
      () => ListMyChallengesUseCase(getIt()),
    )
    ..registerLazySingleton<GetChallengeSummaryUseCaseContract>(
      () => GetChallengeSummaryUseCase(getIt()),
    )
    ..registerLazySingleton<ListCommunityChallengesUseCaseContract>(
      () => ListCommunityChallengesUseCase(getIt()),
    )
    ..registerLazySingleton<ListPendingMilestonesUseCaseContract>(
      () => ListPendingMilestonesUseCase(getIt()),
    )
    ..registerLazySingleton<GetChallengeUseCaseContract>(
      () => GetChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<CreateChallengeUseCaseContract>(
      () => CreateChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateChallengeUseCaseContract>(
      () => UpdateChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteChallengeUseCaseContract>(
      () => DeleteChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<CloneChallengeUseCaseContract>(
      () => CloneChallengeUseCase(getIt()),
    )
    ..registerLazySingleton<SetChallengeCompletionUseCaseContract>(
      () => SetChallengeCompletionUseCase(getIt()),
    )
    ..registerLazySingleton<SetMilestoneCompletionUseCaseContract>(
      () => SetMilestoneCompletionUseCase(getIt()),
    )
    ..registerLazySingleton<RecordChallengeProgressUseCaseContract>(
      () => RecordChallengeProgressUseCase(getIt()),
    )
    ..registerLazySingleton<ListChallengeProgressUseCaseContract>(
      () => ListChallengeProgressUseCase(getIt()),
    )
    ..registerLazySingleton<ReplaceMilestonesUseCaseContract>(
      () => ReplaceMilestonesUseCase(getIt()),
    )
    ..registerLazySingleton<ReorderMilestonesUseCaseContract>(
      () => ReorderMilestonesUseCase(getIt()),
    )
    ..registerLazySingleton<ListChallengeSubjectsUseCaseContract>(
      () => ListChallengeSubjectsUseCase(getIt()),
    )
    ..registerLazySingleton<ListChallengeAttachmentsUseCaseContract>(
      () => ListChallengeAttachmentsUseCase(getIt()),
    )
    ..registerLazySingleton<ListChallengeLinkTargetsUseCaseContract>(
      () => ListChallengeLinkTargetsUseCase(getIt()),
    )
    ..registerLazySingleton<GetChallengeFileUrlUseCaseContract>(
      () => GetChallengeFileUrlUseCase(getIt()),
    );
}
