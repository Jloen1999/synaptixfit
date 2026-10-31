import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/app_language.dart';
import '../../../../../domain/use_cases/profile/get_language_use_case.dart';
import '../../../../../domain/use_cases/profile/set_language_use_case.dart';

part 'language_bloc.freezed.dart';
part 'language_event.dart';
part 'language_state.dart';

/// Idioma de la app (vive en la raíz: los textos cambian al momento al elegir
/// en Ajustes). [initial] es el que se leyó antes de arrancar.
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc({
    required this._get,
    required this._set,
    AppLanguage initial = AppLanguage.system,
  }) : super(LanguageState(language: initial)) {
    on<LanguageStarted>((_, emit) async {
      final language = (await _get()).valueOrNull;
      // Si el usuario ya eligió mientras se leía, manda su elección.
      if (language != null && !_changed) {
        emit(LanguageState(language: language));
      }
    });
    on<LanguageChanged>((event, emit) async {
      _changed = true;
      emit(LanguageState(language: event.language));
      // Si no se puede guardar, el idioma se aplica igual en esta sesión y
      // al volver a abrir la app se usa el que hubiera guardado.
      await _set(event.language);
    });
  }

  final GetLanguageUseCaseContract _get;
  final SetLanguageUseCaseContract _set;
  bool _changed = false;
}
