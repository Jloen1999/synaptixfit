import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/errors/app_error.dart';
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
  }) : super(const QuickCheckInState()) {
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
      await _load(emit);
    });
    on<QuickCheckInEditRequested>(
      (_, emit) =>
          emit(state.copyWith(editing: true, justSent: false, error: null)),
    );
    on<QuickCheckInEditCancelled>(
      (_, emit) => emit(state.copyWith(editing: false, error: null)),
    );
    on<QuickCheckInSubmitted>((event, emit) async {
      if (state.sending) return;
      emit(state.copyWith(sending: true, error: null));
      final result = await _submit(event.input);
      if (result.errorOrNull case final error?) {
        emit(state.copyWith(sending: false, error: error));
        return;
      }
      emit(state.copyWith(sending: false, editing: false, justSent: true));
      await _load(emit);
    });
  }

  final GetTodayAdaptationUseCaseContract _getAdaptation;
  final SubmitQuickCheckInUseCaseContract _submit;
  final WatchDataChangesUseCaseContract _watchDataChanges;

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
