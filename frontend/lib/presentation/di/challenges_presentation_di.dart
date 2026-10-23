import 'package:get_it/get_it.dart';

import '../screens/challenges/attachment_picker/bloc/attachment_picker_bloc.dart';
import '../screens/challenges/challenge_detail/bloc/challenge_detail_bloc.dart';
import '../screens/challenges/challenge_form/bloc/challenge_form_bloc.dart';
import '../screens/challenges/challenges_list/bloc/challenges_list_bloc.dart';
import '../screens/challenges/community_challenges/bloc/community_challenges_bloc.dart';
import '../screens/challenges/link_picker/bloc/link_picker_bloc.dart';
import '../screens/challenges/quick_challenge/bloc/quick_challenge_bloc.dart';

/// Blocs del módulo challenges.
void registerChallengesPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => ChallengesListBloc(
        listMine: getIt(),
        summary: getIt(),
        pending: getIt(),
        setMilestoneCompletion: getIt(),
        getAccount: getIt(),
        watchChanges: getIt(),
      ),
    )
    ..registerFactory(
      () => CommunityChallengesBloc(
        listCommunity: getIt(),
        cloneChallenge: getIt(),
        watchChanges: getIt(),
      ),
    )
    ..registerFactory(
      () => ChallengeDetailBloc(
        getChallenge: getIt(),
        listProgress: getIt(),
        listSubjects: getIt(),
        setCompletion: getIt(),
        setMilestoneCompletion: getIt(),
        recordProgress: getIt(),
        deleteChallenge: getIt(),
        cloneChallenge: getIt(),
        updateChallenge: getIt(),
        reorderMilestones: getIt(),
        getFileUrl: getIt(),
        getAccount: getIt(),
      ),
    )
    ..registerFactory(
      () => ChallengeFormBloc(
        listSubjects: getIt(),
        createChallenge: getIt(),
        getChallenge: getIt(),
        replaceMilestones: getIt(),
        getAccount: getIt(),
      ),
    )
    ..registerFactory(
      () => QuickChallengeBloc(
        listSubjects: getIt(),
        createChallenge: getIt(),
        updateChallenge: getIt(),
      ),
    )
    ..registerFactory(
      () =>
          AttachmentPickerBloc(listSubjects: getIt(), listAttachments: getIt()),
    )
    ..registerFactory(() => LinkPickerBloc(listTargets: getIt()));
}
