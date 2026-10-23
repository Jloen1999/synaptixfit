import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/profile/onboarding_step.dart';
import '../../../../../domain/enums/usage_focus.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/account/change_password_use_case.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/account/update_account_use_case.dart';
import '../../../../../domain/use_cases/profile/complete_onboarding_use_case.dart';
import '../../../../../domain/use_cases/profile/get_onboarding_status_use_case.dart';

part 'onboarding_bloc.freezed.dart';
part 'onboarding_event.dart';
part 'onboarding_state.dart';

/// Flujo de alta: muestra los pasos pendientes en el orden que da el servidor
/// (cuenta → enfoque → perfil físico → perfil académico → asignaturas) y al
/// final cierra el onboarding. Al elegir el enfoque vuelve a pedir el estado:
/// el servidor decide qué pasos corresponden a cada enfoque.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required this._getStatus,
    required this._complete,
    required this._changePassword,
    required this._updateAccount,
    required this._getAccount,
  }) : super(const OnboardingState()) {
    on<OnboardingStarted>(_onStarted);
    on<OnboardingAccountSubmitted>(_onAccountSubmitted);
    on<OnboardingFocusSubmitted>(_onFocusSubmitted);
    on<OnboardingStepCompleted>((_, emit) => _advance(emit));
    on<OnboardingStepSkipped>((_, emit) => _advance(emit));
    on<OnboardingPreviousRequested>(_onPrevious);
    on<OnboardingFinishRequested>((_, emit) => _finish(emit));
  }

  final GetOnboardingStatusUseCaseContract _getStatus;
  final CompleteOnboardingUseCaseContract _complete;
  final ChangePasswordUseCaseContract _changePassword;
  final UpdateAccountUseCaseContract _updateAccount;
  final GetAccountUseCaseContract _getAccount;

  Future<void> _onStarted(
    OnboardingStarted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(status: OnboardingStatusView.loading, error: null));
    final result = await _getStatus();
    switch (result.fold((s) => s, (_) => null)) {
      case null:
        emit(
          state.copyWith(
            status: OnboardingStatusView.failure,
            error: result.errorOrNull,
          ),
        );
      case final status when status.completed:
        emit(state.copyWith(status: OnboardingStatusView.finished));
      case final status:
        final steps = status.pendingSteps;
        if (steps.isEmpty) {
          await _finish(emit);
          return;
        }
        emit(
          state.copyWith(
            status: OnboardingStatusView.ready,
            steps: steps,
            index: 0,
          ),
        );
    }
  }

  /// Paso de cuenta (cuentas de Google): fija la contraseña y, si cambia, el nombre.
  Future<void> _onAccountSubmitted(
    OnboardingAccountSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null));
    final passwordResult = await _changePassword(newPassword: event.password);
    if (passwordResult.errorOrNull case final error?) {
      emit(state.copyWith(busy: false, actionError: error));
      return;
    }
    final name = event.fullName?.trim();
    final accountResult = name == null || name.isEmpty
        ? await _getAccount()
        : await _updateAccount(fullName: name);
    emit(state.copyWith(busy: false, account: accountResult.valueOrNull));
    await _advance(emit);
  }

  /// Guarda el enfoque y deja solo los pasos de los ámbitos elegidos.
  Future<void> _onFocusSubmitted(
    OnboardingFocusSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null));
    final result = await _updateAccount(usageFocus: event.focus);
    if (result.errorOrNull case final error?) {
      emit(state.copyWith(busy: false, actionError: error));
      return;
    }
    // Los pasos ya recorridos se quedan (para poder volver); los siguientes
    // son los pendientes que da el servidor con el enfoque nuevo.
    final done = state.steps.take(state.index + 1).toList();
    final status = (await _getStatus()).valueOrNull;
    final next = status == null
        ? state.steps.skip(state.index + 1).toList()
        : status.pendingSteps.where((s) => !done.contains(s)).toList();
    emit(
      state.copyWith(
        busy: false,
        steps: [...done, ...next],
        account: result.valueOrNull,
      ),
    );
    await _advance(emit);
  }

  void _onPrevious(
    OnboardingPreviousRequested event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.index > 0) emit(state.copyWith(index: state.index - 1));
  }

  Future<void> _advance(Emitter<OnboardingState> emit) async {
    if (state.index + 1 < state.steps.length) {
      emit(state.copyWith(index: state.index + 1, actionError: null));
    } else {
      await _finish(emit);
    }
  }

  Future<void> _finish(Emitter<OnboardingState> emit) async {
    emit(state.copyWith(busy: true, actionError: null));
    final result = await _complete();
    emit(
      result.fold(
        (_) =>
            state.copyWith(busy: false, status: OnboardingStatusView.finished),
        (error) => state.copyWith(busy: false, actionError: error),
      ),
    );
  }
}
