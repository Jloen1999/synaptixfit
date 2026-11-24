import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/academic/answer_in_test_session_use_case.dart';
import '../../../../../domain/use_cases/academic/complete_test_session_use_case.dart';
import '../../../../../domain/use_cases/academic/get_active_test_session_use_case.dart';
import '../../../../../domain/use_cases/academic/start_test_session_use_case.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';

part 'mock_exam_bloc.freezed.dart';
part 'mock_exam_event.dart';
part 'mock_exam_state.dart';

/// Simulacro con sesión persistente en el servidor: se puede reanudar,
/// responder pregunta a pregunta (o «No lo sé», que enseña la respuesta) y
/// entregar. Salir con la flecha lo deja en curso para seguir luego (no hay
/// «Abandonar»: lo respondido ya cuenta). Qué cuenta al entregar lo decide el
/// servidor (ADR 0063): sin respuestas no cuenta ([MockExamState.notCounted]);
/// lo sin contestar pasa a «No lo sé».
class MockExamBloc extends Bloc<MockExamEvent, MockExamState> {
  MockExamBloc({
    required this._getActive,
    required this._start,
    required this._answer,
    required this._complete,
    required this._getAccount,
  }) : super(const MockExamState()) {
    on<MockExamStarted>(_onStarted);
    on<MockExamAnswerChanged>(
      (event, emit) => emit(state.copyWith(draft: event.answer)),
    );
    on<MockExamQuestionSelected>(
      (event, emit) => emit(state.copyWith(index: event.index, draft: '')),
    );
    on<MockExamAnswerSubmitted>((_, emit) => _onAnswer(emit, dontKnow: false));
    on<MockExamDontKnowSubmitted>((_, emit) => _onAnswer(emit, dontKnow: true));
    on<MockExamCompleted>(_onComplete);
  }

  final GetActiveTestSessionUseCaseContract _getActive;
  final StartTestSessionUseCaseContract _start;
  final AnswerInTestSessionUseCaseContract _answer;
  final CompleteTestSessionUseCaseContract _complete;
  final GetAccountUseCaseContract _getAccount;

  Future<void> _onStarted(
    MockExamStarted event,
    Emitter<MockExamState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    TestSession? session;
    if (event.resume) {
      final active = await _getActive(event.materialId);
      if (active.errorOrNull case final AppError error) {
        emit(state.copyWith(loading: false, error: error));
        return;
      }
      session = active.valueOrNull;
    }
    if (session == null) {
      final started = await _start([
        event.materialId,
        ...event.extraMaterialIds,
      ], questionCount: event.questionCount);
      if (started.errorOrNull case final AppError error) {
        emit(state.copyWith(loading: false, error: error));
        return;
      }
      session = started.valueOrNull!;
    }
    emit(
      state.copyWith(
        loading: false,
        session: session,
        index: _firstPending(session),
      ),
    );
  }

  /// Índice de la pregunta por la que seguir (la actual o la primera sin
  /// responder).
  static int _firstPending(TestSession session) {
    final pending = session.questions.indexWhere((q) => !q.answered);
    if (pending >= 0) return pending;
    return session.currentIndex.clamp(0, session.questions.length - 1).toInt();
  }

  /// Manda la respuesta (o «No lo sé»). Tras una respuesta pasa a la
  /// siguiente sin contestar; tras «No lo sé» se queda para leer la solución.
  Future<void> _onAnswer(
    Emitter<MockExamState> emit, {
    required bool dontKnow,
  }) async {
    final session = state.session;
    final question = state.current;
    final answer = state.draft.trim();
    if (session == null || question == null || question.answered) return;
    if (!dontKnow && answer.isEmpty) return;
    emit(state.copyWith(submitting: true, actionError: null));
    final hasNext = state.index < session.questions.length - 1;
    final result = await _answer(
      session.id,
      questionId: question.id,
      answer: dontKnow ? '' : answer,
      nextIndex: hasNext ? state.index + 1 : null,
      dontKnow: dontKnow,
    );
    emit(
      result.fold(
        (r) => state.copyWith(
          submitting: false,
          session: r.session,
          index: dontKnow ? state.index : _nextPending(r.session, state.index),
          draft: '',
        ),
        (error) => state.copyWith(submitting: false, actionError: error),
      ),
    );
  }

  /// Siguiente pregunta sin responder después de [from] (o la misma si no hay).
  static int _nextPending(TestSession session, int from) {
    final qs = session.questions;
    for (var i = 1; i <= qs.length; i++) {
      final candidate = (from + i) % qs.length;
      if (!qs[candidate].answered) return candidate;
    }
    return from;
  }

  Future<void> _onComplete(
    MockExamCompleted event,
    Emitter<MockExamState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;
    emit(state.copyWith(finishing: true, actionError: null));
    final result = await _complete(session.id);
    switch (result.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(finishing: false, actionError: error));
        return;
      case null:
        break;
    }
    final completed = result.valueOrNull!;
    if (!completed.counted) {
      emit(state.copyWith(finishing: false, notCounted: true));
      return;
    }
    Account? account;
    if (completed.xpGranted > 0) {
      account = (await _getAccount()).valueOrNull;
    }
    emit(
      state.copyWith(
        finishing: false,
        session: completed,
        updatedAccount: account,
        closedSessionId: completed.id,
      ),
    );
  }
}
