import 'package:get_it/get_it.dart';

import '../screens/profile/reminder_options/bloc/reminder_options_bloc.dart';
import '../screens/training/activity_history/bloc/activity_history_bloc.dart';
import '../screens/training/cycle/bloc/cycle_bloc.dart';
import '../screens/training/health_consent/bloc/health_consent_bloc.dart';
import '../screens/training/quick_check_in/bloc/quick_check_in_bloc.dart';

/// Blocs de bienestar (ADR 0033).
void registerWellbeingPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => HealthConsentBloc(get: getIt(), give: getIt(), withdraw: getIt()),
    )
    ..registerFactory(
      () => CycleBloc(
        getOverview: getIt(),
        change: getIt(),
        logDay: getIt(),
        listDays: getIt(),
        deleteDay: getIt(),
        deleteHistory: getIt(),
      ),
    )
    ..registerFactory(
      () => QuickCheckInBloc(
        getAdaptation: getIt(),
        submit: getIt(),
        watchDataChanges: getIt(),
      ),
    )
    ..registerFactory(
      () => ActivityHistoryBloc(list: getIt(), watchDataChanges: getIt()),
    )
    ..registerFactory(() => ReminderOptionsBloc(get: getIt(), change: getIt()));
}
