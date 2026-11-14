import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/check_in_answers.dart';
import '../../../../../domain/models/training/wellbeing.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/training/get_check_ins_use_case.dart';
import '../../../../../domain/use_cases/training/get_today_check_in_use_case.dart';
import '../../../../../domain/use_cases/training/submit_check_in_use_case.dart';
import '../../training_effect.dart';

part 'check_in_bloc.freezed.dart';
part 'check_in_event.dart';
part 'check_in_state.dart';

/// Check-in diario (sueño, estrés, energía, agujetas, dolor) con historial.
class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  CheckInBloc({
    required this._getToday,
    required this._getHistory,
    required this._submit,
    required this._getAccount,
  }) : super(const CheckInState()) {
    on<CheckInStarted>(_onStarted);
    on<CheckInInputChanged>((e, emit) => emit(state.copyWith(input: e.input)));
    on<CheckInSubmitted>(_onSubmitted);
    on<CheckInAnswered>(_onAnswered);
    on<CheckInStressChanged>(
      (e, emit) => emit(
        state.copyWith(
          input: state.input.copyWith(stress: e.value),
          stressAnswered: true,
        ),
      ),
    );
  }

  void _onAnswered(CheckInAnswered e, Emitter<CheckInState> emit) {
    final answers = state.answers.withAnswer(e.question, e.value);
    final saves =
        answers.complete &&
        CheckInAnswers.savesOnLastAnswer(
          loggedToday: state.today != null,
          withDetails: e.withDetails,
        );
    emit(
      state.copyWith(
        answers: answers,
        input: _withAnswer(state.input, e.question, e.value),
        saveRequest: saves ? state.saveRequest + 1 : state.saveRequest,
      ),
    );
  }

  static CheckInInput _withAnswer(
    CheckInInput input,
    CheckInQuestion question,
    int value,
  ) => switch (question) {
    CheckInQuestion.sleep => input.copyWith(sleepQuality: value),
    CheckInQuestion.energy => input.copyWith(energy: value),
    CheckInQuestion.soreness => input.copyWith(soreness: value),
  };

  final GetTodayCheckInUseCaseContract _getToday;
  final GetCheckInsUseCaseContract _getHistory;
  final SubmitCheckInUseCaseContract _submit;
  final GetAccountUseCaseContract _getAccount;

  Future<void> _onStarted(
    CheckInStarted event,
    Emitter<CheckInState> emit,
  ) async {
    emit(const CheckInState());
    final initial = event.initial;
    final todayFuture = _getToday();
    final historyFuture = _getHistory(size: 14);
    final today = await todayFuture;
    final history = await historyFuture;
    switch (today) {
      case Success(value: final checkIn):
        emit(
          state.copyWith(
            status: CheckInStatus.ready,
            today: checkIn,
            input: checkIn == null
                ? CheckInQuestion.values.fold(
                    const CheckInInput(),
                    (input, q) => initial[q] == null
                        ? input
                        : _withAnswer(input, q, initial[q]!),
                  )
                : CheckInInput.fromCheckIn(checkIn),
            answers: checkIn == null
                ? initial
                : CheckInAnswers.all(
                    sleep: checkIn.sleepQuality,
                    energy: checkIn.energy,
                    soreness: checkIn.soreness,
                  ),
            stressAnswered: checkIn != null,
            history: history.valueOrNull?.items ?? const [],
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(status: CheckInStatus.failure, error: error));
    }
  }

  Future<void> _onSubmitted(
    CheckInSubmitted event,
    Emitter<CheckInState> emit,
  ) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true));
    final result = await _submit(state.input);
    switch (result) {
      case Success(value: final saved):
        final history = [
          saved.checkIn,
          ...state.history.where((c) => c.id != saved.checkIn.id),
        ];
        emit(
          state.copyWith(
            submitting: false,
            today: saved.checkIn,
            lastResult: saved,
            history: history,
          ),
        );
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.checkInSaved),
        );
        if (saved.xpAwarded > 0) {
          final account = await _getAccount();
          if (account case Success(:final value)) {
            _effect(emit, TrainingEffect.accountChanged(value));
          }
        }
      case Failure(:final error):
        emit(state.copyWith(submitting: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  void _effect(Emitter<CheckInState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
