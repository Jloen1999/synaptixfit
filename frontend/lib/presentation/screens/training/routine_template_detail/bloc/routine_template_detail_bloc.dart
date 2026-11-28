import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/routine_template.dart';
import '../../../../../domain/use_cases/training/get_routine_template_use_case.dart';
import '../../../../../domain/use_cases/training/use_routine_template_use_case.dart';

part 'routine_template_detail_bloc.freezed.dart';
part 'routine_template_detail_event.dart';
part 'routine_template_detail_state.dart';

/// Detalle de una plantilla de rutina: lee sus días y ejercicios con
/// [GetRoutineTemplateUseCaseContract] y la convierte en rutina propia con
/// [UseRoutineTemplateUseCaseContract] (el mismo alta que la lista).
class RoutineTemplateDetailBloc
    extends Bloc<RoutineTemplateDetailEvent, RoutineTemplateDetailState> {
  RoutineTemplateDetailBloc({required this._get, required this._use})
    : super(const RoutineTemplateDetailState()) {
    on<RoutineTemplateDetailStarted>(_onStarted);
    on<RoutineTemplateDetailUsed>(_onUsed);
  }

  final GetRoutineTemplateUseCaseContract _get;
  final UseRoutineTemplateUseCaseContract _use;

  Future<void> _onStarted(
    RoutineTemplateDetailStarted event,
    Emitter<RoutineTemplateDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        templateId: event.templateId,
        status: TemplateDetailStatus.loading,
        error: null,
      ),
    );
    final result = await _get(event.templateId);
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: TemplateDetailStatus.ready,
        detail: value,
      ),
      Failure(:final error) => state.copyWith(
        status: TemplateDetailStatus.failure,
        error: error,
      ),
    });
  }

  Future<void> _onUsed(
    RoutineTemplateDetailUsed event,
    Emitter<RoutineTemplateDetailState> emit,
  ) async {
    final detail = state.detail;
    if (state.using || detail == null) return;
    emit(state.copyWith(using: true, useError: null));
    final result = await _use(detail.summary.id);
    emit(switch (result) {
      Success(:final value) => state.copyWith(using: false, created: value),
      Failure(:final error) => state.copyWith(using: false, useError: error),
    });
    // Efectos de un solo uso: la página ya los ha visto.
    emit(state.copyWith(created: null, useError: null));
  }
}
