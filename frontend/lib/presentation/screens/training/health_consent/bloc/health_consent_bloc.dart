import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/training/health_consent.dart';
import '../../../../../domain/use_cases/training/get_health_consent_use_case.dart';
import '../../../../../domain/use_cases/training/give_health_consent_use_case.dart';
import '../../../../../domain/use_cases/training/withdraw_health_consent_use_case.dart';

part 'health_consent_bloc.freezed.dart';
part 'health_consent_event.dart';
part 'health_consent_state.dart';

/// Permiso expreso para guardar el registro diario (datos de salud, ADR 0034):
/// lo lee, lo da y lo retira. Lo usan la hoja previa al registro
/// ([ensureHealthConsent]) y Ajustes › Privacidad y datos.
class HealthConsentBloc extends Bloc<HealthConsentEvent, HealthConsentState> {
  HealthConsentBloc({
    required this._get,
    required this._give,
    required this._withdraw,
  }) : super(const HealthConsentState()) {
    on<HealthConsentStarted>(_onStarted);
    on<HealthConsentGiven>(_onGiven);
    on<HealthConsentWithdrawn>(_onWithdrawn);
  }

  final GetHealthConsentUseCaseContract _get;
  final GiveHealthConsentUseCaseContract _give;
  final WithdrawHealthConsentUseCaseContract _withdraw;

  Future<void> _onStarted(
    HealthConsentStarted event,
    Emitter<HealthConsentState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    final result = await _get();
    emit(
      result.fold(
        (consent) => state.copyWith(loading: false, consent: consent),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }

  Future<void> _onGiven(
    HealthConsentGiven event,
    Emitter<HealthConsentState> emit,
  ) async {
    emit(state.copyWith(saving: true, saveError: null));
    final result = await _give();
    emit(
      result.fold(
        (_) => state.copyWith(
          saving: false,
          consent: HealthConsent(given: true, givenAt: DateTime.now()),
        ),
        (error) => state.copyWith(saving: false, saveError: error),
      ),
    );
  }

  Future<void> _onWithdrawn(
    HealthConsentWithdrawn event,
    Emitter<HealthConsentState> emit,
  ) async {
    emit(state.copyWith(saving: true, saveError: null));
    final result = await _withdraw(deleteRecords: event.deleteRecords);
    emit(
      result.fold(
        (_) => state.copyWith(
          saving: false,
          consent: HealthConsent(
            given: false,
            givenAt: state.consent?.givenAt,
            withdrawnAt: DateTime.now(),
          ),
          withdrawals: state.withdrawals + 1,
        ),
        (error) => state.copyWith(saving: false, saveError: error),
      ),
    );
  }
}
