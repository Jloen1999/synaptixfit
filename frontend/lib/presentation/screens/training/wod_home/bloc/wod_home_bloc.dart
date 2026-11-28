import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/wod.dart';
import '../../../../../domain/use_cases/training/get_wod_board_use_case.dart';
import '../../../../../domain/use_cases/training/list_wod_marks_use_case.dart';
import '../../../../../domain/use_cases/training/list_wod_templates_use_case.dart';
import '../../../../../domain/use_cases/training/save_wod_result_use_case.dart';

part 'wod_home_bloc.freezed.dart';
part 'wod_home_event.dart';
part 'wod_home_state.dart';

/// Apartado WOD de Entreno (ADR 0069): la pizarra de hoy (mi WOD o una
/// plantilla de ejemplo), Rx o Adaptado, apuntar una marca sin cronómetro y
/// «Mis marcas». Qué WOD toca y cuál es la mejor marca lo decide el servidor.
class WodHomeBloc extends Bloc<WodHomeEvent, WodHomeState> {
  WodHomeBloc({
    required this._getBoard,
    required this._listTemplates,
    required this._listMarks,
    required this._saveResult,
  }) : super(const WodHomeState()) {
    on<WodHomeStarted>((_, emit) => _load(emit, showLoading: true));
    on<WodHomeRefreshed>((_, emit) => _load(emit));
    on<WodHomeTemplateChosen>((e, emit) {
      emit(state.copyWith(templateCode: e.code));
      return _load(emit);
    });
    on<WodHomeDivisionChanged>(
      (e, emit) => emit(state.copyWith(division: e.division)),
    );
    on<WodHomeResultSubmitted>(_onResult);
  }

  final GetWodBoardUseCaseContract _getBoard;
  final ListWodTemplatesUseCaseContract _listTemplates;
  final ListWodMarksUseCaseContract _listMarks;
  final SaveWodResultUseCaseContract _saveResult;

  Future<void> _load(
    Emitter<WodHomeState> emit, {
    bool showLoading = false,
  }) async {
    if (showLoading) {
      emit(state.copyWith(status: WodHomeStatus.loading, error: null));
    }
    final (board, templates, marks) = await (
      _getBoard(templateCode: state.templateCode),
      _listTemplates(),
      _listMarks(),
    ).wait;
    switch (board) {
      case Failure(:final error):
        // Con la pizarra ya en pantalla, un refresco fallido no la quita.
        if (state.board == null) {
          emit(state.copyWith(status: WodHomeStatus.failure, error: error));
        } else {
          emit(state.copyWith(actionError: error));
          emit(state.copyWith(actionError: null));
        }
      case Success(:final value):
        emit(
          state.copyWith(
            status: WodHomeStatus.ready,
            error: null,
            board: value,
            templates: templates.valueOrNull ?? state.templates,
            marks: marks.valueOrNull ?? state.marks,
          ),
        );
    }
  }

  Future<void> _onResult(
    WodHomeResultSubmitted e,
    Emitter<WodHomeState> emit,
  ) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true, saved: null, actionError: null));
    final result = await _saveResult(e.wod, e.draft);
    switch (result) {
      case Failure(:final error):
        emit(state.copyWith(saving: false, actionError: error));
        emit(state.copyWith(actionError: null));
      case Success(:final value):
        // La plantilla ya es mi WOD de hoy: se deja de pedir como ejemplo.
        emit(state.copyWith(saving: false, saved: value, templateCode: null));
        await _load(emit);
    }
  }
}
