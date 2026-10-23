import 'package:get_it/get_it.dart';

import '../screens/home/dashboard/bloc/home_dashboard_bloc.dart';
import '../screens/home/home_onboarding_gate.dart';

/// Blocs del módulo home.
void registerHomePresentation(GetIt getIt) {
  getIt
    ..registerLazySingleton(HomeOnboardingGate.new)
    ..registerFactory(
      () => HomeDashboardBloc(
        getDashboard: getIt(),
        getDueReviews: getIt(),
        getUnreadCount: getIt(),
        getOnboardingStatus: getIt(),
        getTimeline: getIt(),
        onboardingGate: getIt(),
        watchChanges: getIt(),
        startSession: getIt(),
      ),
    );
}
