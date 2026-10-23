import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/use_cases/profile/delete_my_account_use_case.dart';
import '../../../../../domain/use_cases/profile/export_my_data_use_case.dart';

part 'settings_bloc.freezed.dart';
part 'settings_event.dart';
part 'settings_state.dart';

/// Ajustes: exportar mis datos y eliminar la cuenta.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required this._exportMyData, required this._deleteMyAccount})
    : super(const SettingsState()) {
    on<SettingsExportRequested>(_onExport);
    on<SettingsDeleteRequested>(_onDelete);
  }

  final ExportMyDataUseCaseContract _exportMyData;
  final DeleteMyAccountUseCaseContract _deleteMyAccount;

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
