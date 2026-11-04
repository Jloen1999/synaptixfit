import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/training/today_adaptation.dart';
import '../../../../../domain/use_cases/training/get_today_adaptation_use_case.dart';
import '../../../../../domain/use_cases/training/submit_quick_check_in_use_case.dart';

part 'quick_check_in_bloc.freezed.dart';
part 'quick_check_in_event.dart';
part 'quick_check_in_state.dart';

/// Registro rápido de la tarjeta de Rutinas: tres toques (sueño, energía y
/// agujetas) y, después, cómo se adapta hoy el entreno y por qué. La
/// adaptación la decide el servidor.
class QuickCheckInBloc extends Bloc<QuickCheckInEvent, QuickCheckInState> {
  QuickCheckInBloc({required this._getAdaptation, required this._submit})
    : super(const QuickCheckInState()) {
    on<QuickCheckInStarted>((_, emit) => _load(emit));
    on<QuickCheckInEditRequested>(
      (_, emit) => emit(state.copyWith(editing: true, error: null)),
    );
    on<QuickCheckInSubmitted>((event, emit) async {
      if (state.sending) return;
      emit(state.copyWith(sending: true, error: null));
      final result = await _submit(event.input);
      if (result.errorOrNull case final error?) {
        emit(state.copyWith(sending: false, error: error));
        return;
      }
      emit(state.copyWith(sending: false, editing: false));
      await _load(emit);
    });
  }

  final GetTodayAdaptationUseCaseContract _getAdaptation;
  final SubmitQuickCheckInUseCaseContract _submit;

  Future<void> _load(Emitter<QuickCheckInState> emit) async {
    final result = await _getAdaptation();
    emit(
      state.copyWith(
        loading: false,
        adaptation: result.valueOrNull ?? state.adaptation,
        error: result.errorOrNull,
      ),
    );
  }
}
