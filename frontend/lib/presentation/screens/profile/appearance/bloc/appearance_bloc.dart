import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/appearance_mode.dart';
import '../../../../../domain/use_cases/profile/get_appearance_use_case.dart';
import '../../../../../domain/use_cases/profile/set_appearance_use_case.dart';

part 'appearance_bloc.freezed.dart';
part 'appearance_event.dart';
part 'appearance_state.dart';

/// Apariencia de la app (vive en la raíz: el tema cambia al momento al elegir
/// en Ajustes). Se aplica antes de guardar para que no haya espera.
/// [initial] es la que se leyó antes de arrancar (sin destello de tema).
class AppearanceBloc extends Bloc<AppearanceEvent, AppearanceState> {
  AppearanceBloc({
    required this._get,
    required this._set,
    AppearanceMode initial = AppearanceMode.dark,
  }) : super(AppearanceState(mode: initial)) {
    on<AppearanceStarted>((_, emit) async {
      final mode = (await _get()).valueOrNull;
      // Si el usuario ya eligió mientras se leía, manda su elección.
      if (mode != null && !_changed) emit(AppearanceState(mode: mode));
    });
    on<AppearanceChanged>((event, emit) async {
      _changed = true;
      emit(AppearanceState(mode: event.mode));
      await _set(event.mode);
    });
  }

  final GetAppearanceUseCaseContract _get;
  final SetAppearanceUseCaseContract _set;
  bool _changed = false;
}
