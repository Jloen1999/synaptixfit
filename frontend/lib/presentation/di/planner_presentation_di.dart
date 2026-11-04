import 'package:get_it/get_it.dart';

import '../../domain/models/planner/calendar_block.dart';
import '../screens/planner/block_editor/bloc/block_editor_bloc.dart';
import '../screens/planner/calendar/bloc/calendar_bloc.dart';
import '../screens/planner/calendar_sync/bloc/calendar_sync_bloc.dart';
import '../screens/planner/deadlines/bloc/deadlines_bloc.dart';
import '../screens/planner/past_study/bloc/past_study_bloc.dart';
import '../screens/planner/pomodoro/bloc/pomodoro_bloc.dart';
import '../screens/planner/schedule_scan/bloc/schedule_scan_bloc.dart';
import '../screens/planner/suggestions/bloc/suggestions_bloc.dart';
import '../screens/planner/weekly_load/bloc/weekly_load_bloc.dart';

/// Blocs del módulo planner.
void registerPlannerPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => PastStudyBloc(
        logPastStudy: getIt(),
        getSubjects: getIt(),
        getAccount: getIt(),
      ),
    )
    ..registerFactory(
      () => CalendarBloc(
        getBlocks: getIt(),
        getConflicts: getIt(),
        getTimeline: getIt(),
        getBalance: getIt(),
        reschedule: getIt(),
        setCompletion: getIt(),
        savePlan: getIt(),
        getWeekClosed: getIt(),
        getAccount: getIt(),
        deleteBlock: getIt(),
        rescheduleNext: getIt(),
      ),
    )
    // El bloque en edición (o `null` al crear) llega como parámetro.
    ..registerFactoryParam<BlockEditorBloc, CalendarBlock?, void>(
      (block, _) => BlockEditorBloc(
        getSubjects: getIt(),
        getRoutines: getIt(),
        getChallenges: getIt(),
        getDeadlines: getIt(),
        createBlock: getIt(),
        updateBlock: getIt(),
        reschedule: getIt(),
        distribute: getIt(),
        block: block,
      ),
    )
    ..registerFactory(
      () => WeeklyLoadBloc(
        getBalance: getIt(),
        getLoad: getIt(),
        updateWellbeing: getIt(),
        syncLoad: getIt(),
        getAccount: getIt(),
      ),
    )
    ..registerFactory(
      () => DeadlinesBloc(
        getDeadlines: getIt(),
        getDeadline: getIt(),
        getSubjects: getIt(),
        createDeadline: getIt(),
        updateDeadline: getIt(),
        deleteDeadline: getIt(),
        setCompletion: getIt(),
        getAccount: getIt(),
      ),
    )
    ..registerFactory(
      () => SuggestionsBloc(suggest: getIt(), createBlock: getIt()),
    )
    ..registerFactory(
      () => CalendarSyncBloc(
        getFeed: getIt(),
        createFeed: getIt(),
        revokeFeed: getIt(),
        importGeneral: getIt(),
      ),
    )
    ..registerFactory(
      () => ScheduleScanBloc(
        getSubjects: getIt(),
        scanSchedule: getIt(),
        saveSemesterDates: getIt(),
        importIcs: getIt(),
        exportIcs: getIt(),
      ),
    )
    // Una sola instancia: el temporizador sigue al salir de la pantalla y lo
    // muestra el armazón de pestañas.
    ..registerLazySingleton(
      () => PomodoroBloc(
        recordSession: getIt(),
        getStats: getIt(),
        getAccount: getIt(),
        getPlan: getIt(),
        scheduleAlert: getIt(),
        cancelAlert: getIt(),
        updateOngoing: getIt(),
        loadTimer: getIt(),
        saveTimer: getIt(),
        clearTimer: getIt(),
        getSubjects: getIt(),
        setBlockCompletion: getIt(),
      ),
    );
}
