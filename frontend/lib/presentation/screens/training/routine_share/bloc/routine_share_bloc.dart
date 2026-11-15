import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/training/get_routine_share_status_use_case.dart';
import '../../../../../domain/use_cases/training/share_routine_link_use_case.dart';
import '../../../../../domain/use_cases/training/stop_sharing_routine_use_case.dart';

part 'routine_share_bloc.freezed.dart';
part 'routine_share_event.dart';
part 'routine_share_state.dart';

/// Hoja «Compartir esta rutina» (ADR 0043): sabe hasta cuándo se comparte,
/// crea un enlace y abre el menú del sistema, y deja de compartir.
class RoutineShareBloc extends Bloc<RoutineShareEvent, RoutineShareState> {
  RoutineShareBloc({
    required this._status,
    required this._share,
    required this._stop,
  }) : super(const RoutineShareState()) {
    on<RoutineShareStarted>(_onStarted);
    on<RoutineShareRequested>(_onShare);
    on<RoutineShareStopRequested>(_onStop);
  }

  final GetRoutineShareStatusUseCaseContract _status;
  final ShareRoutineLinkUseCaseContract _share;
  final StopSharingRoutineUseCaseContract _stop;

  Future<void> _onStarted(
    RoutineShareStarted event,
    Emitter<RoutineShareState> emit,
  ) async {
    emit(
      state.copyWith(
        routineId: event.routineId,
        status: RoutineShareStatus.loading,
      ),
    );
    final result = await _status(event.routineId);
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: RoutineShareStatus.ready,
        sharedUntil: value,
      ),
      Failure(:final error) => state.copyWith(
        status: RoutineShareStatus.failure,
        error: error,
      ),
    });
  }

  Future<void> _onShare(
    RoutineShareRequested event,
    Emitter<RoutineShareState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, actionError: null));
    final result = await _share(state.routineId, message: event.message);
    emit(switch (result) {
      // El último enlace manda: es el que vence más tarde.
      Success(:final value) => state.copyWith(
        busy: false,
        sharedUntil: value.expiresAt,
      ),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
  }

  Future<void> _onStop(
    RoutineShareStopRequested event,
    Emitter<RoutineShareState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, actionError: null));
    final result = await _stop(state.routineId);
    emit(switch (result) {
      Success() => state.copyWith(
        busy: false,
        sharedUntil: null,
        stopped: true,
      ),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(stopped: false));
  }
}
