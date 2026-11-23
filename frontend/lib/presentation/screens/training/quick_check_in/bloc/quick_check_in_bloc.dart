import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/training/check_in_answers.dart';
import '../../../../../domain/models/training/today_adaptation.dart';
import '../../../../../domain/use_cases/training/get_today_adaptation_use_case.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../../domain/use_cases/training/submit_quick_check_in_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';

part 'quick_check_in_bloc.freezed.dart';
part 'quick_check_in_event.dart';
part 'quick_check_in_state.dart';

/// Registro rápido de la tarjeta de Rutinas: tres toques (sueño, energía y
/// agujetas) y, después, cómo se adapta hoy el entreno y por qué. La
/// adaptación la decide el servidor. Se refresca si el registro cambia en
/// otra pantalla (registro completo).
class QuickCheckInBloc extends Bloc<QuickCheckInEvent, QuickCheckInState>
    with DataChangeRefreshMixin {
  QuickCheckInBloc({
    required this._getAdaptation,
    required this._submit,
    required this._watchDataChanges,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const QuickCheckInState()) {
    on<QuickCheckInStarted>((_, emit) async {
      watchDataChanges(
        _watchDataChanges,
        topics: const {DataTopic.training},
        onChanged: const QuickCheckInEvent.refreshed(),
      );
      emit(state.copyWith(justSent: false));
      await _load(emit);
    });
    on<QuickCheckInRefreshed>((_, emit) async {
      if (state.sending || state.editing) return;
      if (state.loadError != null) emit(state.copyWith(reloading: true));
      await _load(emit);
    });
    on<QuickCheckInEditRequested>((_, emit) {
      // Al cambiar, se parte de lo que ya se contestó hoy.
      final today = state.adaptation?.todayAnswers ?? state.saved;
      emit(
        state.copyWith(
          editing: true,
          justSent: false,
          saveError: null,
          answers: today == null
              ? const CheckInAnswers()
              : CheckInAnswers.all(
                  sleep: today.sleepQuality,
                  energy: today.energy,
                  soreness: today.soreness,
                ),
        ),
      );
    });
    on<QuickCheckInAnswered>((e, emit) {
      final answers = state.answers.withAnswer(e.question, e.value);
      final saves =
          answers.complete &&
          CheckInAnswers.savesOnLastAnswer(
            loggedToday: state.editing,
            withDetails: false,
          );
      emit(
        state.copyWith(
          answers: answers,
          saveRequest: saves ? state.saveRequest + 1 : state.saveRequest,
        ),
      );
    });
    on<QuickCheckInEditCancelled>(
      (_, emit) => emit(
        state.copyWith(
          editing: false,
          saveError: null,
          answers: const CheckInAnswers(),
        ),
      ),
    );
    on<QuickCheckInSubmitted>((event, emit) async {
      if (state.sending) return;
      emit(state.copyWith(sending: true, saveError: null));
      final result = await _submit(event.input);
      if (result.errorOrNull case final error?) {
        emit(state.copyWith(sending: false, saveError: error));
        return;
      }
      final savedAt = _clock();
      // La adaptación nueva llega en el mismo estado que «Guardado»: la
      // tarjeta lo anuncia una vez con la explicación ya al día (ADR 0062).
      // Si no llega, lo guardado cuenta igual y se dice que falta la lectura.
      final adaptation = await _getAdaptation();
      emit(
        state.copyWith(
          loading: false,
          sending: false,
          editing: false,
          justSent: true,
          savedAt: savedAt,
          saved: event.input,
          answers: const CheckInAnswers(),
          adaptation: adaptation.valueOrNull ?? state.adaptation,
          loadError: adaptation.errorOrNull,
        ),
      );
    });
  }

  final GetTodayAdaptationUseCaseContract _getAdaptation;
  final SubmitQuickCheckInUseCaseContract _submit;
  final WatchDataChangesUseCaseContract _watchDataChanges;
  final DateTime Function() _clock;

  Future<void> _load(Emitter<QuickCheckInState> emit) async {
    final result = await _getAdaptation();
    emit(
      state.copyWith(
        loading: false,
        adaptation: result.valueOrNull ?? state.adaptation,
        loadError: result.errorOrNull,
        reloading: false,
      ),
    );
  }
}
