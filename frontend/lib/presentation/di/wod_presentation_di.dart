import 'package:get_it/get_it.dart';

import '../screens/training/wod_editor/bloc/wod_editor_bloc.dart';
import '../screens/training/wod_home/bloc/wod_home_bloc.dart';
import '../screens/training/wod_live/bloc/wod_live_bloc.dart';

/// Blocs del apartado WOD de Entreno (ADR 0069).
void registerWodPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => WodHomeBloc(
        getBoard: getIt(),
        listTemplates: getIt(),
        listMarks: getIt(),
        saveResult: getIt(),
      ),
    )
    ..registerFactory(
      () => WodEditorBloc(create: getIt(), update: getIt(), delete: getIt()),
    )
    ..registerFactory(() => WodLiveBloc(saveResult: getIt()));
}
