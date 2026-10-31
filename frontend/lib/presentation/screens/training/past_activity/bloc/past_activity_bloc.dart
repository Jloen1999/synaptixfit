import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/planner/log_past_activity_use_case.dart';

part 'past_activity_bloc.freezed.dart';
part 'past_activity_event.dart';
part 'past_activity_state.dart';

/// «Apuntar actividad»: guarda una actividad física ya pasada. Las reglas (de
/// los últimos 7 días, ya terminada, topes de XP) las decide el servidor.
class PastActivityBloc extends Bloc<PastActivityEvent, PastActivityState> {
  PastActivityBloc({required this._logPastActivity, required this._getAccount})
    : super(const PastActivityState()) {
    on<PastActivitySubmitted>(_onSubmitted);
  }

  final LogPastActivityUseCaseContract _logPastActivity;
  final GetAccountUseCaseContract _getAccount;

  Future<void> _onSubmitted(
    PastActivitySubmitted event,
    Emitter<PastActivityState> emit,
  ) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, error: null));
    final result = await _logPastActivity(
      start: event.start,
      minutes: event.minutes,
      effort: event.effort,
      title: event.title,
    );
    switch (result.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(submitting: false, error: error));
        return;
      case null:
        break;
    }
    final xp = result.valueOrNull?.xpDelta ?? 0;
    // Con XP, el nivel de la cuenta cambia: se refresca para la cabecera.
    final account = xp > 0 ? (await _getAccount()).valueOrNull : null;
    emit(
      state.copyWith(submitting: false, savedXp: xp, updatedAccount: account),
    );
  }
}
