import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/reminders/reminder_options.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/use_cases/reminders/change_reminder_options_use_case.dart';
import '../../../../../domain/use_cases/reminders/get_reminder_options_use_case.dart';

part 'reminder_options_bloc.freezed.dart';
part 'reminder_options_event.dart';
part 'reminder_options_state.dart';

/// Opciones de los avisos del móvil (interruptores, antelación, días antes de
/// una entrega, tareas de reto y resumen de la mañana). Cada cambio se ve al
/// momento, se guarda en el servidor y se deshace si falla. Al guardarse, el
/// bus de cambios (`/notifications` → `DataTopic.social`) hace que
/// `RemindersBloc` vuelva a pedir el plan de avisos.
class ReminderOptionsBloc
    extends Bloc<ReminderOptionsEvent, ReminderOptionsState> {
  ReminderOptionsBloc({required this._get, required this._change})
    : super(const ReminderOptionsState()) {
    on<ReminderOptionsStarted>((_, emit) async {
      emit(state.copyWith(loading: true, error: null));
      final result = await _get();
      if (result.valueOrNull case final options?) _confirmed = options;
      emit(
        state.copyWith(
          loading: false,
          options: result.valueOrNull ?? state.options,
          error: result.errorOrNull,
        ),
      );
    });
    on<ReminderOptionsChanged>((event, emit) async {
      // Tocar la opción ya elegida no cambia nada: ni petición ni «Guardado».
      // Entregas y exámenes necesitan al menos un día: la pantalla lo explica
      // y el servidor lo rechazaría; aquí solo es una defensa.
      if (event.options == state.options ||
          event.options.deadlineDaysBefore.isEmpty) {
        return;
      }
      final request = ++_lastRequest;
      emit(
        state.copyWith(
          options: event.options,
          saving: true,
          saved: false,
          saveError: null,
          unsaved: null,
        ),
      );
      final result = await _enqueue(request, event.options);
      // Si llegó otro cambio mientras tanto, su respuesta decide el estado.
      if (result == null || request != _lastRequest) return;
      switch (result.errorOrNull) {
        case final error?:
          emit(
            state.copyWith(
              options: _confirmed,
              saving: false,
              saveError: error,
              unsaved: event.options,
            ),
          );
        case null:
          emit(
            state.copyWith(
              options: result.valueOrNull ?? event.options,
              saving: false,
              saved: true,
            ),
          );
      }
    });
  }

  /// Los envíos van en fila: cada uno lleva todas las opciones, así que si dos
  /// salieran a la vez el servidor podría quedarse con el más viejo. Uno que
  /// ya tiene otro detrás no se envía (nulo): el siguiente lo incluye.
  Future<AppResult<ReminderOptions>?> _enqueue(
    int request,
    ReminderOptions options,
  ) {
    final next = _queue.then((_) async {
      if (request != _lastRequest) return null;
      final result = await _change(options);
      if (result.valueOrNull case final saved?) _confirmed = saved;
      return result;
    });
    _queue = next.then((_) {});
    return next;
  }

  final GetReminderOptionsUseCaseContract _get;
  final ChangeReminderOptionsUseCaseContract _change;

  /// Lo último que confirmó el servidor: a esto se vuelve si un cambio falla.
  ReminderOptions _confirmed = const ReminderOptions();
  int _lastRequest = 0;
  Future<void> _queue = Future.value();
}
