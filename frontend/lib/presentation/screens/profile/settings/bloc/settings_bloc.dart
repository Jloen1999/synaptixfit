import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/use_cases/auth/has_unsent_data_use_case.dart';
import '../../../../../domain/use_cases/guides/reset_guides_use_case.dart';
import '../../../../../domain/use_cases/profile/delete_my_account_use_case.dart';
import '../../../../../domain/use_cases/profile/export_my_data_use_case.dart';

part 'settings_bloc.freezed.dart';
part 'settings_event.dart';
part 'settings_state.dart';

/// Ajustes: exportar mis datos, eliminar la cuenta, decidir si «Cerrar
/// sesión» se confirma (solo si se perdería algo sin subir) y «Ver las guías
/// otra vez» (ADR 0049).
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required this._exportMyData,
    required this._deleteMyAccount,
    required this._hasUnsentData,
    required this._resetGuides,
  }) : super(const SettingsState()) {
    on<SettingsExportRequested>(_onExport);
    on<SettingsDeleteRequested>(_onDelete);
    on<SettingsLogoutRequested>(_onLogout);
    on<SettingsGuidesResetRequested>(_onGuidesReset);
  }

  final ExportMyDataUseCaseContract _exportMyData;
  final DeleteMyAccountUseCaseContract _deleteMyAccount;
  final HasUnsentDataUseCaseContract _hasUnsentData;
  final ResetGuidesUseCaseContract _resetGuides;

  /// Las guías vuelven a salir la próxima vez que se entre en cada pantalla.
  Future<void> _onGuidesReset(
    SettingsGuidesResetRequested event,
    Emitter<SettingsState> emit,
  ) async {
    // Se limpia el resultado anterior para que un segundo toque vuelva a avisar.
    if (state.outcome != null || state.error != null) {
      emit(state.copyWith(outcome: null, error: null));
    }
    final result = await _resetGuides(accountId: event.accountId);
    emit(
      result.fold(
        (_) => state.copyWith(outcome: SettingsOutcome.guidesReset),
        (error) => state.copyWith(error: error),
      ),
    );
  }

  /// Cerrar sesión es reversible (se vuelve a entrar), así que no pregunta;
  /// solo si hay datos sin subir, que se borrarían, se confirma. Si no se puede
  /// comprobar, se confirma por si acaso.
  Future<void> _onLogout(
    SettingsLogoutRequested event,
    Emitter<SettingsState> emit,
  ) async {
    // Se limpia el resultado anterior para que un segundo toque vuelva a avisar.
    if (state.outcome != null || state.error != null) {
      emit(state.copyWith(outcome: null, error: null));
    }
    final unsent = (await _hasUnsentData()).valueOrNull ?? true;
    emit(
      state.copyWith(
        outcome: unsent
            ? SettingsOutcome.confirmLogout
            : SettingsOutcome.loggedOut,
      ),
    );
  }

  Future<void> _onExport(
    SettingsExportRequested event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.exporting) return;
    emit(state.copyWith(exporting: true, outcome: null, error: null));
    final result = await _exportMyData();
    emit(
      result.fold(
        (saved) => state.copyWith(
          exporting: false,
          outcome: saved
              ? SettingsOutcome.exported
              : SettingsOutcome.exportCancelled,
        ),
        (error) => state.copyWith(exporting: false, error: error),
      ),
    );
  }

  Future<void> _onDelete(
    SettingsDeleteRequested event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.deleting) return;
    emit(state.copyWith(deleting: true, outcome: null, error: null));
    final password = event.password?.trim();
    final result = await _deleteMyAccount(
      password: password == null || password.isEmpty ? null : event.password,
      confirm: event.confirm,
    );
    emit(
      result.fold(
        (_) =>
            state.copyWith(deleting: false, outcome: SettingsOutcome.deleted),
        (error) => state.copyWith(deleting: false, error: error),
      ),
    );
  }
}
