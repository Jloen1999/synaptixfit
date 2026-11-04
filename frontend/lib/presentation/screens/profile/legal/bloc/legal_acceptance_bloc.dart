import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/profile/accept_legal_terms_use_case.dart';
import '../../../../../domain/use_cases/profile/get_legal_acceptance_use_case.dart';

part 'legal_acceptance_bloc.freezed.dart';
part 'legal_acceptance_event.dart';
part 'legal_acceptance_state.dart';

/// Puerta de la política de privacidad (ADR 0034). Es una sola instancia para
/// toda la app: al iniciar sesión comprueba si hay que aceptar la versión
/// vigente (nunca aceptada, p. ej. al entrar con Google, o actualizada) y el
/// router lleva a `/legal-acceptance` antes que al onboarding o a los permisos.
/// Lo decide el servidor; aquí solo se guarda qué versión se enseña.
class LegalAcceptanceBloc
    extends Bloc<LegalAcceptanceEvent, LegalAcceptanceState> {
  LegalAcceptanceBloc({required this._getAcceptance, required this._accept})
    : super(const LegalAcceptanceState()) {
    on<LegalAcceptanceChecked>(_onChecked);
    on<LegalAcceptanceAccepted>(_onAccepted);
    on<LegalAcceptanceReset>((_, emit) => emit(const LegalAcceptanceState()));
  }

  final GetLegalAcceptanceUseCaseContract _getAcceptance;
  final AcceptLegalTermsUseCaseContract _accept;

  Future<void> _onChecked(
    LegalAcceptanceChecked event,
    Emitter<LegalAcceptanceState> emit,
  ) async {
    final status = (await _getAcceptance()).valueOrNull;
    // Sin conexión no se bloquea la app: se volverá a comprobar al entrar.
    if (status == null || !status.mustAccept) {
      emit(state.copyWith(status: LegalGateStatus.accepted));
      return;
    }
    emit(
      state.copyWith(
        status: LegalGateStatus.required,
        currentVersion: status.currentVersion,
        updated: status.acceptedVersion != null,
      ),
    );
  }

  Future<void> _onAccepted(
    LegalAcceptanceAccepted event,
    Emitter<LegalAcceptanceState> emit,
  ) async {
    final version = state.currentVersion;
    if (version == null) return;
    emit(state.copyWith(accepting: true, error: null));
    final result = await _accept(version);
    switch (result) {
      case Success():
        emit(
          state.copyWith(accepting: false, status: LegalGateStatus.accepted),
        );
      case Failure(:final error):
        emit(state.copyWith(accepting: false, error: error));
        // La política cambió mientras se leía: se enseña la nueva versión.
        if (error case BusinessError(code: 'LEGAL_VERSION_OUTDATED')) {
          add(const LegalAcceptanceEvent.checked());
        }
    }
  }
}
