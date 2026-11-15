import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/routine_share.dart';
import '../../../../../domain/use_cases/training/copy_shared_routine_use_case.dart';
import '../../../../../domain/use_cases/training/preview_shared_routine_use_case.dart';

part 'shared_routine_bloc.freezed.dart';
part 'shared_routine_event.dart';
part 'shared_routine_state.dart';

/// Rutina abierta desde un enlace (ADR 0043): carga el resumen y la copia a
/// «Mis rutinas» con un toque.
class SharedRoutineBloc extends Bloc<SharedRoutineEvent, SharedRoutineState> {
  SharedRoutineBloc({required this._preview, required this._copy})
    : super(const SharedRoutineState()) {
    on<SharedRoutineStarted>(_onStarted);
    on<SharedRoutineCopyRequested>(_onCopy);
  }

  final PreviewSharedRoutineUseCaseContract _preview;
  final CopySharedRoutineUseCaseContract _copy;

  Future<void> _onStarted(
    SharedRoutineStarted event,
    Emitter<SharedRoutineState> emit,
  ) async {
    emit(
      state.copyWith(
        token: event.token,
        status: SharedRoutineStatus.loading,
        error: null,
      ),
    );
    final result = await _preview(event.token);
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: SharedRoutineStatus.ready,
        preview: value,
      ),
      Failure(:final error) => state.copyWith(
        status: SharedRoutineStatus.failure,
        error: error,
      ),
    });
  }

  Future<void> _onCopy(
    SharedRoutineCopyRequested event,
    Emitter<SharedRoutineState> emit,
  ) async {
    if (state.copying) return;
    emit(state.copyWith(copying: true, copyError: null));
    final result = await _copy(state.token);
    emit(switch (result) {
      Success(:final value) => state.copyWith(copying: false, copied: value),
      Failure(:final error) => state.copyWith(copying: false, copyError: error),
    });
    emit(state.copyWith(copied: null, copyError: null));
  }
}
