import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/mock_exam_options.dart';
import '../../../../../domain/use_cases/academic/get_mock_exam_options_use_case.dart';

part 'mock_exam_setup_bloc.freezed.dart';
part 'mock_exam_setup_event.dart';
part 'mock_exam_setup_state.dart';

/// Prepara un simulacro de asignatura: qué apuntes y archivos entran y
/// cuántas preguntas. Los límites los da el servidor ([MockExamOptions]).
class MockExamSetupBloc extends Bloc<MockExamSetupEvent, MockExamSetupState> {
  MockExamSetupBloc({required this._getOptions})
    : super(const MockExamSetupState()) {
    on<MockExamSetupStarted>(_onStarted);
    on<MockExamSetupSourceToggled>(_onToggled);
    on<MockExamSetupAllToggled>(_onAllToggled);
    on<MockExamSetupCountChanged>(
      (event, emit) => emit(state.copyWith(count: event.count)),
    );
  }

  final GetMockExamOptionsUseCaseContract _getOptions;

  Future<void> _onStarted(
    MockExamSetupStarted event,
    Emitter<MockExamSetupState> emit,
  ) async {
    emit(
      state.copyWith(subjectId: event.subjectId, loading: true, error: null),
    );
    final result = await _getOptions(event.subjectId);
    result.fold((options) {
      // Por defecto entra todo (hasta el máximo): lo normal es repasar la
      // asignatura entera; quitar es más fácil que buscar qué añadir.
      final selected = {
        for (final s in options.sources.take(options.maxMaterials))
          s.materialId,
      };
      emit(
        _withValidCount(
          state.copyWith(
            loading: false,
            options: options,
            selected: selected,
            count: options.suggestedQuestions,
          ),
        ),
      );
    }, (error) => emit(state.copyWith(loading: false, error: error)));
  }

  void _onToggled(
    MockExamSetupSourceToggled event,
    Emitter<MockExamSetupState> emit,
  ) {
    final options = state.options;
    if (options == null) return;
    final selected = {...state.selected};
    if (!selected.remove(event.materialId)) {
      if (selected.length >= options.maxMaterials) return;
      selected.add(event.materialId);
    }
    emit(_withValidCount(state.copyWith(selected: selected)));
  }

  void _onAllToggled(
    MockExamSetupAllToggled event,
    Emitter<MockExamSetupState> emit,
  ) {
    final options = state.options;
    if (options == null) return;
    final selected = state.allSelected
        ? <String>{}
        : {
            for (final s in options.sources.take(options.maxMaterials))
              s.materialId,
          };
    emit(_withValidCount(state.copyWith(selected: selected)));
  }

  /// Si con lo elegido hay menos preguntas que las pedidas, se ajusta a una
  /// de las opciones que sí se pueden hacer.
  MockExamSetupState _withValidCount(MockExamSetupState s) {
    final choices = s.countChoices;
    if (choices.isEmpty || choices.contains(s.count)) return s;
    return s.copyWith(
      count: choices.lastWhere(
        (c) => c <= s.count,
        orElse: () => choices.first,
      ),
    );
  }
}
