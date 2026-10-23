import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../../domain/use_cases/academic/generate_question_bank_use_case.dart';
import '../../../../../domain/use_cases/academic/get_active_test_session_use_case.dart';
import '../../../../../domain/use_cases/academic/get_question_bank_use_case.dart';
import '../../../../../domain/use_cases/academic/get_study_material_use_case.dart';
import '../../../../../domain/use_cases/academic/get_test_sessions_use_case.dart';

part 'practice_hub_bloc.freezed.dart';
part 'practice_hub_event.dart';
part 'practice_hub_state.dart';

/// Práctica de un material: banco de preguntas, modos (libre, flashcards,
/// simulacro), simulacro en curso e historial.
class PracticeHubBloc extends Bloc<PracticeHubEvent, PracticeHubState> {
  PracticeHubBloc({
    required this._getMaterial,
    required this._getBank,
    required this._generateBank,
    required this._getActiveSession,
    required this._getSessions,
  }) : super(const PracticeHubState()) {
    on<PracticeHubStarted>((event, emit) async {
      emit(state.copyWith(materialId: event.materialId));
      await _load(emit, silent: false);
    });
    on<PracticeHubRefreshed>((_, emit) => _load(emit, silent: true));
    on<PracticeHubBankRequested>(_onGenerate);
  }

  final GetStudyMaterialUseCaseContract _getMaterial;
  final GetQuestionBankUseCaseContract _getBank;
  final GenerateQuestionBankUseCaseContract _generateBank;
  final GetActiveTestSessionUseCaseContract _getActiveSession;
  final GetTestSessionsUseCaseContract _getSessions;

  Future<void> _load(
    Emitter<PracticeHubState> emit, {
    required bool silent,
  }) async {
    if (!silent) emit(state.copyWith(loading: true, error: null));
    final id = state.materialId;
    final (material, bank, active, sessions) = await (
      _getMaterial(id),
      _getBank(id),
      _getActiveSession(id),
      _getSessions(id),
    ).wait;
    final error = material.errorOrNull ?? bank.errorOrNull;
    emit(
      error != null
          ? state.copyWith(loading: false, error: error)
          : state.copyWith(
              loading: false,
              error: null,
              material: material.valueOrNull,
              bank: bank.valueOrNull,
              activeSession: active.valueOrNull,
              sessions: sessions.valueOrNull ?? const [],
            ),
    );
  }

  Future<void> _onGenerate(
    PracticeHubBankRequested event,
    Emitter<PracticeHubState> emit,
  ) async {
    emit(state.copyWith(generating: true, actionError: null));
    final result = await _generateBank(state.materialId);
    emit(
      result.fold(
        (bank) => state.copyWith(generating: false, bank: bank),
        (error) => state.copyWith(generating: false, actionError: error),
      ),
    );
  }
}
