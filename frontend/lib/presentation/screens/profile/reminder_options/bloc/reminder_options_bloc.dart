import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/reminders/reminder_options.dart';
import '../../../../../domain/use_cases/reminders/change_reminder_options_use_case.dart';
import '../../../../../domain/use_cases/reminders/get_reminder_options_use_case.dart';

part 'reminder_options_bloc.freezed.dart';
part 'reminder_options_event.dart';
part 'reminder_options_state.dart';

/// Interruptores de los avisos opcionales del móvil (racha, registro diario y
/// clases). El cambio se ve al momento y se deshace si el servidor falla.
class ReminderOptionsBloc
    extends Bloc<ReminderOptionsEvent, ReminderOptionsState> {
  ReminderOptionsBloc({required this._get, required this._change})
    : super(const ReminderOptionsState()) {
    on<ReminderOptionsStarted>((_, emit) async {
      emit(state.copyWith(loading: true, error: null));
      final result = await _get();
      emit(
        state.copyWith(
          loading: false,
          options: result.valueOrNull ?? state.options,
          error: result.errorOrNull,
        ),
      );
    });
    on<ReminderOptionsChanged>((event, emit) async {
      final before = state.options;
      emit(state.copyWith(options: event.options, saveError: null));
      final result = await _change(event.options);
      if (result.errorOrNull case final error?) {
        emit(state.copyWith(options: before, saveError: error));
      }
    });
  }

  final GetReminderOptionsUseCaseContract _get;
  final ChangeReminderOptionsUseCaseContract _change;
}
