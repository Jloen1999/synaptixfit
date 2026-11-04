import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/planner/log_past_activity_use_case.dart';
import '../../../../../domain/use_cases/training/get_pending_day_use_case.dart';
import '../../../../../domain/use_cases/training/get_routine_use_case.dart';
import '../../../../../domain/use_cases/training/log_past_session_use_case.dart';

part 'past_activity_bloc.freezed.dart';
part 'past_activity_event.dart';
part 'past_activity_state.dart';

/// «Apuntar actividad»: guarda una actividad física ya pasada (deporte libre)
/// o un día de la rutina en curso hecho sin la app, que avanza la rutina y
/// cuenta en su fecha. Las reglas (de los últimos 7 días, ya terminada, topes
/// de XP) las decide el servidor.
class PastActivityBloc extends Bloc<PastActivityEvent, PastActivityState> {
  PastActivityBloc({
    required this._logPastActivity,
    required this._getAccount,
    required this._getPendingDay,
    required this._getRoutine,
    required this._logPastSession,
  }) : super(const PastActivityState()) {
    on<PastActivitySubmitted>(_onSubmitted);
    on<PastActivityRoutineRequested>(_onRoutineRequested);
    on<PastActivityRoutineSessionSubmitted>(_onRoutineSessionSubmitted);
  }

  final LogPastActivityUseCaseContract _logPastActivity;
  final GetAccountUseCaseContract _getAccount;
  final GetPendingDayUseCaseContract _getPendingDay;
  final GetRoutineUseCaseContract _getRoutine;
  final LogPastSessionUseCaseContract _logPastSession;

  Future<void> _onRoutineRequested(
    PastActivityRoutineRequested event,
    Emitter<PastActivityState> emit,
  ) async {
    if (state.routineLoaded || state.loadingRoutine) return;
    emit(state.copyWith(loadingRoutine: true, routineError: null));
    final pending = await _getPendingDay();
    final day = pending.valueOrNull;
    final routineResult = day == null ? null : await _getRoutine(day.routineId);
    final error = pending.errorOrNull ?? routineResult?.errorOrNull;
    // Con error no se da por cargada: así «Reintentar» vuelve a pedirla y no
    // se muestra un falso «no tienes rutina en curso».
    emit(
      state.copyWith(
        loadingRoutine: false,
        routineLoaded: error == null,
        routineError: error,
        routine: routineResult?.valueOrNull,
        pendingDayId: day?.dayId,
      ),
    );
  }

  Future<void> _onRoutineSessionSubmitted(
    PastActivityRoutineSessionSubmitted event,
    Emitter<PastActivityState> emit,
  ) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, error: null));
    final result = await _logPastSession(
      routineId: event.routineId,
      dayId: event.dayId,
      date: event.date,
      durationMinutes: event.minutes,
      rpe: event.rpe,
    );
    switch (result.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(submitting: false, error: error));
        return;
      case null:
        break;
    }
    final xp = result.valueOrNull?.experience.xpDelta ?? 0;
    final account = xp > 0 ? (await _getAccount()).valueOrNull : null;
    emit(
      state.copyWith(submitting: false, savedXp: xp, updatedAccount: account),
    );
  }

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
      kind: event.kind,
      distanceMeters: event.distanceMeters,
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
