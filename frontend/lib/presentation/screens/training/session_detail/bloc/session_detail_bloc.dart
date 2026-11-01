import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/use_cases/training/get_routine_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_highlights_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_use_case.dart';

part 'session_detail_bloc.freezed.dart';
part 'session_detail_event.dart';
part 'session_detail_state.dart';

/// Detalle de solo lectura de una sesión terminada: sus series agrupadas por
/// ejercicio (nombres y fotos de la rutina) y lo destacado (volumen, récords).
/// Corregir, desmarcar y eliminar los hace el historial al volver.
class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required this._getSession,
    required this._getRoutine,
    required this._getHighlights,
  }) : super(const SessionDetailState()) {
    on<SessionDetailStarted>(_onStarted);
  }

  final GetSessionUseCaseContract _getSession;
  final GetRoutineUseCaseContract _getRoutine;
  final GetSessionHighlightsUseCaseContract _getHighlights;

  /// Con [SessionDetailStarted.entry] (desde el historial) ya se tiene la
  /// sesión; sin ella (enlace directo) se carga y no se sabe si es de hoy.
  Future<void> _onStarted(
    SessionDetailStarted event,
    Emitter<SessionDetailState> emit,
  ) async {
    var entry = event.entry;
    emit(SessionDetailState(entry: entry));
    if (entry == null) {
      final result = await _getSession(event.sessionId);
      switch (result) {
        case Success(value: final session):
          entry = SessionHistoryEntry(session: session);
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
}
