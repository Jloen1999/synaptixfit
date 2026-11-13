import 'package:get_it/get_it.dart';

import '../screens/training/past_activity/bloc/past_activity_bloc.dart';
import '../screens/training/exercise_alternatives/bloc/exercise_alternatives_bloc.dart';
import '../screens/training/check_in/bloc/check_in_bloc.dart';
import '../screens/training/community/bloc/community_bloc.dart';
import '../screens/training/exercise_detail/bloc/exercise_detail_bloc.dart';
import '../screens/training/exercise_guide/bloc/exercise_guide_bloc.dart';
import '../screens/training/exercise_explorer/bloc/exercise_explorer_bloc.dart';
import '../screens/training/live_session/bloc/live_session_bloc.dart';
import '../screens/training/routine_detail/bloc/routine_detail_bloc.dart';
import '../screens/training/routine_editor/bloc/routine_editor_bloc.dart';
import '../screens/training/session_completed/bloc/session_completed_bloc.dart';
import '../screens/training/session_detail/bloc/session_detail_bloc.dart';
import '../screens/training/session_history/bloc/session_history_bloc.dart';
import '../screens/training/training_home/bloc/training_home_bloc.dart';
import '../screens/training/weekly_plan/bloc/weekly_plan_bloc.dart';
import '../screens/shell/bloc/open_session_bar_bloc.dart';
import '../screens/training/routine_templates/bloc/routine_templates_bloc.dart';
import '../screens/training/exercise_progress/bloc/exercise_progress_bloc.dart';

/// Blocs del módulo training.
void registerTrainingPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => PastActivityBloc(
        logPastActivity: getIt(),
        getAccount: getIt(),
        getPendingDay: getIt(),
        getRoutine: getIt(),
        logPastSession: getIt(),
      ),
    )
    ..registerFactory(() => ExerciseAlternativesBloc(getAlternatives: getIt()))
    ..registerFactory(
      () => TrainingHomeBloc(
        getPendingDay: getIt(),
        getMyRoutines: getIt(),
        getTodayCheckIn: getIt(),
        getRecommendations: getIt(),
        applyRecommendation: getIt(),
        discardRecommendation: getIt(),
        startSession: getIt(),
        watchChanges: getIt(),
        getOpenSessions: getIt(),
        skipDay: getIt(),
        finishSession: getIt(),
        discardSession: getIt(),
        restartRoutine: getIt(),
      ),
    )
    ..registerFactory(
      () => RoutineEditorBloc(
        generate: getIt(),
        refine: getIt(),
        create: getIt(),
      ),
    )
    ..registerFactory(
      () => RoutineDetailBloc(
        RoutineDetailUseCases(
          getRoutine: getIt(),
          getBodyWeight: getIt(),
          updateRoutine: getIt(),
          changeStatus: getIt(),
          deleteRoutine: getIt(),
          duplicateRoutine: getIt(),
          cloneRoutine: getIt(),
          addWeek: getIt(),
          updateWeek: getIt(),
          deleteWeek: getIt(),
          addDay: getIt(),
          renameDay: getIt(),
          deleteDay: getIt(),
          addExercise: getIt(),
          reorderExercises: getIt(),
          updateExercise: getIt(),
          removeExercise: getIt(),
          replaceExercise: getIt(),
          startSession: getIt(),
          getMyRoutines: getIt(),
          skipDay: getIt(),
          unskipDay: getIt(),
          restartRoutine: getIt(),
        ),
      ),
    )
    ..registerFactory(
      () => ExerciseExplorerBloc(search: getIt(), getFilters: getIt()),
    )
    ..registerFactory(() => ExerciseDetailBloc(getExercise: getIt()))
    ..registerFactory(
      () => ExerciseGuideBloc(
        getTips: getIt(),
        getNote: getIt(),
        saveNote: getIt(),
      ),
    )
    ..registerFactory(
      () => OpenSessionBarBloc(
        getOpenSessions: getIt(),
        watchDataChanges: getIt(),
      ),
    )
    ..registerFactory(
      () => LiveSessionBloc(
        getSession: getIt(),
        getRoutine: getIt(),
        recordSet: getIt(),
        deleteSet: getIt(),
        finish: getIt(),
        cancel: getIt(),
        getAccount: getIt(),
        getLastPerformance: getIt(),
        getBookends: getIt(),
        getAdaptation: getIt(),
        getLoadSuggestions: getIt(),
        loadPending: getIt(),
        savePending: getIt(),
        pauseSession: getIt(),
        resumeSession: getIt(),
        loadDraft: getIt(),
        saveDraft: getIt(),
      ),
    )
    ..registerFactory(
      () => SessionCompletedBloc(
        getSession: getIt(),
        apply: getIt(),
        discard: getIt(),
        getHighlights: getIt(),
        createPost: getIt(),
        getStreak: getIt(),
        listChallenges: getIt(),
      ),
    )
    ..registerFactory(() => RoutineTemplatesBloc(list: getIt(), use: getIt()))
    ..registerFactory(() => ExerciseProgressBloc(get: getIt()))
    ..registerFactory(
      () => SessionDetailBloc(
        getSession: getIt(),
        getRoutine: getIt(),
        getHighlights: getIt(),
      ),
    )
    ..registerFactory(
      () => SessionHistoryBloc(
        getHistory: getIt(),
        getRecords: getIt(),
        unmark: getIt(),
        getAccount: getIt(),
        getOpen: getIt(),
        correct: getIt(),
        delete: getIt(),
        finish: getIt(),
        discard: getIt(),
      ),
    )
    ..registerFactory(
      () => CheckInBloc(
        getToday: getIt(),
        getHistory: getIt(),
        submit: getIt(),
        getAccount: getIt(),
      ),
    )
    ..registerFactory(
      () => WeeklyPlanBloc(
        getPlan: getIt(),
        getPlans: getIt(),
        savePlan: getIt(),
        deletePlan: getIt(),
        getPendingDay: getIt(),
      ),
    )
    ..registerFactory(
      () => CommunityBloc(getCommunity: getIt(), clone: getIt()),
    );
}
