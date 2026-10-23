import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/academic/answer_question_use_case.dart';
import '../../../../../domain/use_cases/academic/complete_practice_use_case.dart';
import '../../../../../domain/use_cases/academic/get_question_bank_use_case.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';

part 'free_practice_bloc.freezed.dart';
part 'free_practice_event.dart';
part 'free_practice_state.dart';

/// Práctica libre: una pregunta tras otra con corrección inmediata y, al
/// terminar, el resultado con la XP.
class FreePracticeBloc extends Bloc<FreePracticeEvent, FreePracticeState> {
  FreePracticeBloc({
    required this._getBank,
    required this._answer,
    required this._complete,
    required this._getAccount,
  }) : super(const FreePracticeState()) {
    on<FreePracticeStarted>(_onStarted);
    on<FreePracticeAnswerChanged>(
      (event, emit) => emit(state.copyWith(draft: event.answer)),
    );
    on<FreePracticeChecked>(_onChecked);
    on<FreePracticeNextRequested>(_onNext);
    on<FreePracticeFinished>(_onFinished);
  }

  final GetQuestionBankUseCaseContract _getBank;
  final AnswerQuestionUseCaseContract _answer;
  final CompletePracticeUseCaseContract _complete;
  final GetAccountUseCaseContract _getAccount;

  Future<void> _onStarted(
    FreePracticeStarted event,
    Emitter<FreePracticeState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    final result = await _getBank(event.materialId);
    emit(
      result.fold(
        (bank) => bank == null || bank.questions.isEmpty
            ? state.copyWith(
                loading: false,
                error: const AppError.business('QUIZ_BANK_EMPTY'),
              )
            : state.copyWith(loading: false, bank: bank),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }

  Future<void> _onChecked(
    FreePracticeChecked event,
    Emitter<FreePracticeState> emit,
  ) async {
    final question = state.current;
    final answer = state.draft.trim();
    if (question == null || answer.isEmpty) return;
    emit(state.copyWith(checking: true, actionError: null));
    final result = await _answer(question.id, answer);
    emit(
      result.fold(
        (r) => state.copyWith(
          checking: false,
          answers: {...state.answers, question.id: answer},
          results: {...state.results, question.id: r},
        ),
        (error) => state.copyWith(checking: false, actionError: error),
      ),
    );
  }

  void _onNext(
    FreePracticeNextRequested event,
    Emitter<FreePracticeState> emit,
  ) {
    if (state.isLast) return;
    emit(state.copyWith(index: state.index + 1, draft: ''));
  }

  Future<void> _onFinished(
    FreePracticeFinished event,
    Emitter<FreePracticeState> emit,
  ) async {
    final bank = state.bank;
    if (bank == null || state.answers.isEmpty) return;
    emit(state.copyWith(finishing: true, actionError: null));
    final result = await _complete(bank.id, state.answers);
    switch (result.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(finishing: false, actionError: error));
        return;
      case null:
        break;
    }
    emit(state.copyWith(finishing: false, result: result.valueOrNull));
    if ((result.valueOrNull?.xpAwarded ?? 0) > 0) {
      final account = await _getAccount();
      if (account.valueOrNull case final Account a) {
        emit(state.copyWith(updatedAccount: a));
      }
    }
  }
}
