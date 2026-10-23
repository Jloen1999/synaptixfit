import 'package:get_it/get_it.dart';

import '../screens/shell/bloc/reminders_bloc.dart';

/// Blocs de los recordatorios locales del móvil.
void registerRemindersPresentation(GetIt getIt) {
  getIt.registerFactory(
    () => RemindersBloc(
      sync: getIt(),
      clear: getIt(),
      watchChanges: getIt(),
      watchEnabled: getIt(),
      watchOpened: getIt(),
    ),
  );
}
