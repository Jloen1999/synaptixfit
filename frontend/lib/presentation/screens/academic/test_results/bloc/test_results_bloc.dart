import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../../domain/use_cases/academic/get_study_material_use_case.dart';
import '../../../../../domain/use_cases/academic/get_test_session_use_case.dart';

part 'test_results_bloc.freezed.dart';
part 'test_results_event.dart';
part 'test_results_state.dart';

/// Resultados de un simulacro terminado (con la solución de cada pregunta) y
/// la asignatura de su apunte, para que «Nuevo simulacro» prepare otro de la
/// asignatura (pudo mezclar varios apuntes).
class TestResultsBloc extends Bloc<TestResultsEvent, TestResultsState> {
  TestResultsBloc({required this._getSession, required this._getMaterial})
    : super(const TestResultsState()) {
    on<TestResultsStarted>(_onStarted);
  }

  final GetTestSessionUseCaseContract _getSession;
  final GetStudyMaterialUseCaseContract _getMaterial;

  Future<void> _onStarted(
    TestResultsStarted event,
    Emitter<TestResultsState> emit,
  ) async {
    emit(
      state.copyWith(sessionId: event.sessionId, loading: true, error: null),
    );
    final result = await _getSession(event.sessionId);
    final session = result.valueOrNull;
    // Sin el apunte (borrado, sin red) los resultados salen igual.
    final material = session == null
        ? null
        : (await _getMaterial(session.materialId)).valueOrNull;
    emit(
      result.fold(
        (s) => state.copyWith(
          loading: false,
          session: s,
          subjectId: material?.subjectId,
        ),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }
}
