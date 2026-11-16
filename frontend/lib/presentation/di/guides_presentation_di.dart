import 'package:get_it/get_it.dart';

import '../screens/shell/bloc/guide_tour_bloc.dart';
import '../screens/shell/widgets/first_time_guide.dart';

/// Guías la primera vez (ADR 0049): un bloc por pantalla y el coordinador
/// común, que la app raíz pone sobre el navegador.
void registerGuidesPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => GuideTourBloc(shouldShow: getIt(), markSeen: getIt()),
    )
    ..registerLazySingleton(
      () => GuideCoordinator(createBloc: () => getIt<GuideTourBloc>()),
    );
}
