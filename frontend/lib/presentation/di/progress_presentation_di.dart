import 'package:get_it/get_it.dart';

import '../screens/progress/analytics/bloc/analytics_bloc.dart';
import '../screens/progress/badges/bloc/badges_bloc.dart';
import '../screens/progress/overview/bloc/progress_overview_bloc.dart';

/// Blocs del módulo progress.
void registerProgressPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => ProgressOverviewBloc(getOverview: getIt(), watchChanges: getIt()),
    )
    ..registerFactory(
      () => BadgesBloc(
        getCatalog: getIt(),
        changeVisibility: getIt(),
        shareBadge: getIt(),
      ),
    )
    ..registerFactory(
      () => AnalyticsBloc(getReport: getIt(), getCorrelation: getIt()),
    );
}
