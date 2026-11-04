import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/routine_template.dart';
import '../../../../../domain/use_cases/training/list_routine_templates_use_case.dart';
import '../../../../../domain/use_cases/training/use_routine_template_use_case.dart';

part 'routine_templates_bloc.freezed.dart';
part 'routine_templates_event.dart';
part 'routine_templates_state.dart';

/// Plantillas de rutina listas para usar: las lista, filtra lo que se ve y
/// convierte una en rutina propia con un toque.
class RoutineTemplatesBloc
    extends Bloc<RoutineTemplatesEvent, RoutineTemplatesState> {
  RoutineTemplatesBloc({required this._list, required this._use})
    : super(const RoutineTemplatesState()) {
    on<RoutineTemplatesStarted>(_onStarted);
    on<RoutineTemplatesFilterChanged>(
      (e, emit) => emit(state.copyWith(filter: e.filter)),
    );
    on<RoutineTemplatesUsed>(_onUsed);
  }

  final ListRoutineTemplatesUseCaseContract _list;
  final UseRoutineTemplateUseCaseContract _use;

  Future<void> _onStarted(
    RoutineTemplatesStarted event,
    Emitter<RoutineTemplatesState> emit,
  ) async {
    emit(state.copyWith(status: TemplatesStatus.loading, error: null));
    final result = await _list();
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: TemplatesStatus.ready,
        templates: value,
      ),
      Failure(:final error) => state.copyWith(
        status: TemplatesStatus.failure,
        error: error,
      ),
    });
  }

  Future<void> _onUsed(
    RoutineTemplatesUsed event,
    Emitter<RoutineTemplatesState> emit,
  ) async {
    if (state.usingId != null) return;
    emit(state.copyWith(usingId: event.templateId, useError: null));
    final result = await _use(event.templateId);
    emit(switch (result) {
      Success(:final value) => state.copyWith(usingId: null, created: value),
      Failure(:final error) => state.copyWith(usingId: null, useError: error),
    });
    emit(state.copyWith(created: null, useError: null));
  }
}
