import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/wod.dart';
import '../../../../../domain/use_cases/training/create_wod_use_case.dart';
import '../../../../../domain/use_cases/training/delete_wod_use_case.dart';
import '../../../../../domain/use_cases/training/update_wod_use_case.dart';

part 'wod_editor_bloc.freezed.dart';
part 'wod_editor_event.dart';
part 'wod_editor_state.dart';

/// Guardar o borrar mi WOD (ADR 0069). El formulario vive en la página; las
/// reglas de cada formato las valida el servidor.
class WodEditorBloc extends Bloc<WodEditorEvent, WodEditorState> {
  WodEditorBloc({
    required this._create,
    required this._update,
    required this._delete,
  }) : super(const WodEditorState()) {
    on<WodEditorSaveRequested>(_onSave);
    on<WodEditorDeleteRequested>(_onDelete);
  }

  final CreateWodUseCaseContract _create;
  final UpdateWodUseCaseContract _update;
  final DeleteWodUseCaseContract _delete;

  Future<void> _onSave(
    WodEditorSaveRequested e,
    Emitter<WodEditorState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(saving: true, error: null));
    final result = e.wod.id == null
        ? await _create(e.wod)
        : await _update(e.wod);
    switch (result) {
      case Failure(:final error):
        emit(state.copyWith(saving: false, error: error));
      case Success():
        emit(state.copyWith(saving: false, outcome: WodEditorOutcome.saved));
    }
  }

  Future<void> _onDelete(
    WodEditorDeleteRequested e,
    Emitter<WodEditorState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(deleting: true, error: null));
    final result = await _delete(e.wodId);
    switch (result) {
      case Failure(:final error):
        emit(state.copyWith(deleting: false, error: error));
      case Success():
        emit(
          state.copyWith(deleting: false, outcome: WodEditorOutcome.deleted),
        );
    }
  }
}
