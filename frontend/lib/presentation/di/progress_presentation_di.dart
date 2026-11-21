import 'package:get_it/get_it.dart';

import '../screens/progress/analytics/bloc/analytics_bloc.dart';
import '../screens/progress/badges/bloc/badges_bloc.dart';
import '../screens/progress/community/bloc/community_bloc.dart';
import '../screens/progress/overview/bloc/progress_overview_bloc.dart';

/// Blocs del módulo progress.
void registerProgressPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => ProgressOverviewBloc(
        getOverview: getIt(),
        getToday: getIt(),
        getDueMaterials: getIt(),
        watchChanges: getIt(),
        pauseStreak: getIt(),
        resumeStreak: getIt(),
      ),
    )
    ..registerFactory(
      () => BadgesBloc(
        getCatalog: getIt(),
        changeVisibility: getIt(),
        shareBadge: getIt(),
        shareImage: getIt(),
        watchChanges: getIt(),
      ),
    )
    ..registerFactory(
      () => CommunityBloc(
        getFriendships: getIt(),
        acceptRequest: getIt(),
        rejectRequest: getIt(),
        getTogether: getIt(),
        getPosts: getIt(),
        watchChanges: getIt(),
      ),
    )
    ..registerFactory(
      () => AnalyticsBloc(getReport: getIt(), getCorrelation: getIt()),
    );
}
