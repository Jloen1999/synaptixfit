import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/academic/abandon_test_session_use_case.dart';
import '../../../../../domain/use_cases/academic/answer_in_test_session_use_case.dart';
import '../../../../../domain/use_cases/academic/complete_test_session_use_case.dart';
import '../../../../../domain/use_cases/academic/get_active_test_session_use_case.dart';
import '../../../../../domain/use_cases/academic/start_test_session_use_case.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';

part 'mock_exam_bloc.freezed.dart';
part 'mock_exam_event.dart';
part 'mock_exam_state.dart';

/// Simulacro con sesión persistente en el servidor: se puede reanudar,
/// responder pregunta a pregunta, terminar o abandonar.
class MockExamBloc extends Bloc<MockExamEvent, MockExamState> {
  MockExamBloc({
    required this._getActive,
    required this._start,
    required this._answer,
    required this._complete,
    required this._abandon,
    required this._getAccount,
  }) : super(const MockExamState()) {
    on<MockExamStarted>(_onStarted);
    on<MockExamAnswerChanged>(
      (event, emit) => emit(state.copyWith(draft: event.answer)),
    );
    on<MockExamQuestionSelected>(
      (event, emit) => emit(state.copyWith(index: event.index, draft: '')),
    );
    on<MockExamAnswerSubmitted>(_onAnswer);
    on<MockExamCompleted>(_onComplete);
    on<MockExamAbandoned>(_onAbandon);
  }

  final GetActiveTestSessionUseCaseContract _getActive;
  final StartTestSessionUseCaseContract _start;
  final AnswerInTestSessionUseCaseContract _answer;
  final CompleteTestSessionUseCaseContract _complete;
  final AbandonTestSessionUseCaseContract _abandon;
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

  Future<void> _onAnswer(
    MockExamAnswerSubmitted event,
    Emitter<MockExamState> emit,
  ) async {
    final session = state.session;
    final question = state.current;
    final answer = state.draft.trim();
    if (session == null || question == null || answer.isEmpty) return;
    emit(state.copyWith(submitting: true, actionError: null));
    final hasNext = state.index < session.questions.length - 1;
    final result = await _answer(
      session.id,
      questionId: question.id,
      answer: answer,
      nextIndex: hasNext ? state.index + 1 : null,
    );
    emit(
      result.fold((r) {
        final next = _nextPending(r.session, state.index);
        return state.copyWith(
          submitting: false,
          session: r.session,
          index: next,
          draft: '',
        );
      }, (error) => state.copyWith(submitting: false, actionError: error)),
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

  Future<void> _onAbandon(
    MockExamAbandoned event,
    Emitter<MockExamState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;
    emit(state.copyWith(finishing: true, actionError: null));
    final result = await _abandon(session.id);
    emit(
      result.fold(
        (s) => state.copyWith(finishing: false, session: s, abandoned: true),
        (error) => state.copyWith(finishing: false, actionError: error),
      ),
    );
  }
}
