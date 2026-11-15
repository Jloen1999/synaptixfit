import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/training/correct_session_use_case.dart';
import '../../../../../domain/use_cases/training/delete_session_use_case.dart';
import '../../../../../domain/use_cases/training/get_routine_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_highlights_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_history_entry_use_case.dart';
import '../../../../../domain/use_cases/training/unmark_session_use_case.dart';
import '../../training_effect.dart';

part 'session_detail_bloc.freezed.dart';
part 'session_detail_event.dart';
part 'session_detail_state.dart';

/// Detalle de una sesión terminada: sus series agrupadas por ejercicio (nombres
/// y fotos de la rutina) y lo destacado (volumen, récords). «Corregir»,
/// «Reabrir y seguir» y «Eliminar» los hace este bloc con sus casos de uso, así
/// que también funcionan abierto sin pila (aviso, enlace, recarga en web;
/// ADR 0046). Al volver, el historial lee otra vez.
class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required this._getEntry,
    required this._getRoutine,
    required this._getHighlights,
    required this._correct,
    required this._unmark,
    required this._delete,
    required this._getAccount,
  }) : super(const SessionDetailState()) {
    on<SessionDetailStarted>(_onStarted);
    on<SessionDetailCorrectRequested>(_onCorrect);
    on<SessionDetailReopenRequested>(_onReopen);
    on<SessionDetailDeleteRequested>(_onDelete);
  }

  final GetSessionHistoryEntryUseCaseContract _getEntry;
  final GetRoutineUseCaseContract _getRoutine;
  final GetSessionHighlightsUseCaseContract _getHighlights;
  final CorrectSessionUseCaseContract _correct;
  final UnmarkSessionUseCaseContract _unmark;
  final DeleteSessionUseCaseContract _delete;
  final GetAccountUseCaseContract _getAccount;

  /// Con [SessionDetailStarted.entry] (desde el historial) ya se tiene la
  /// sesión; sin ella (enlace directo) se pide como en el historial, con la
  /// foto que elige el servidor.
  Future<void> _onStarted(
    SessionDetailStarted event,
    Emitter<SessionDetailState> emit,
  ) async {
    var entry = event.entry;
    emit(SessionDetailState(entry: entry));
    if (entry == null) {
      final result = await _getEntry(event.sessionId);
      switch (result) {
        case Success(value: final loaded):
          entry = loaded;
        case Failure(:final error):
          emit(
            state.copyWith(status: SessionDetailStatus.failure, error: error),
          );
          return;
      }
    }
    // Nombres y fotos de los ejercicios: de la rutina. Si ya no existe, las
    // series se muestran igual, sin nombre.
    final routineId = entry.session.routineId;
    final routine = routineId == null
        ? null
        : (await _getRoutine(routineId)).valueOrNull;
    final exercises = <String, PlannedExercise>{
      for (final week in routine?.weeks ?? const <RoutineWeek>[])
        for (final day in week.days)
          for (final e in day.exercises) e.id: e,
    };
    emit(
      state.copyWith(
        status: SessionDetailStatus.ready,
        entry: entry,
        exercises: exercises,
      ),
    );
    final highlights = await _getHighlights(entry.session.id);
    if (highlights.valueOrNull case final h?) {
      emit(state.copyWith(highlights: h));
    }
  }

  /// Corrige esfuerzo y duración y se queda en el detalle, ya corregido.
  Future<void> _onCorrect(
    SessionDetailCorrectRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final entry = state.entry;
    if (entry == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _correct(
      entry.session.id,
      rpe: event.rpe,
      durationMinutes: event.minutes,
    );
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(busy: false, entry: entry.copyWith(session: value)),
        );
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.sessionCorrected),
        );
      case Failure(:final error):
        emit(state.copyWith(busy: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  /// «Reabrir y seguir» (solo la terminada hoy): el servidor la desmarca (y
  /// resta su XP) y se entra en la sesión en vivo.
  Future<void> _onReopen(
    SessionDetailReopenRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final entry = state.entry;
    if (entry == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _unmark(entry.session.id);
    switch (result) {
      case Success():
        emit(state.copyWith(busy: false, reopened: entry.session.id));
        emit(state.copyWith(reopened: null));
        await _accountChanged(emit);
      case Failure(:final error):
        emit(state.copyWith(busy: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  /// Eliminar (confirmado en la pantalla): la borra para siempre y se sale.
  Future<void> _onDelete(
    SessionDetailDeleteRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final entry = state.entry;
    if (entry == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _delete(entry.session.id);
    switch (result) {
      case Success():
        emit(state.copyWith(busy: false, deleted: true));
        await _accountChanged(emit);
      case Failure(:final error):
        emit(state.copyWith(busy: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  /// Reabrir o eliminar resta la XP de la sesión: la cuenta se pone al día.
  Future<void> _accountChanged(Emitter<SessionDetailState> emit) async {
    final account = (await _getAccount()).valueOrNull;
    if (account != null && !isClosed) {
      _effect(emit, TrainingEffect.accountChanged(account));
    }
  }

  void _effect(Emitter<SessionDetailState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
