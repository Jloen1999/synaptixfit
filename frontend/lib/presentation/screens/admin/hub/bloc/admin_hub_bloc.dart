import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/admin/lockdown_status.dart';
import '../../../../../domain/use_cases/admin/get_lockdown_use_case.dart';
import '../../../../../domain/use_cases/admin/set_lockdown_use_case.dart';

part 'admin_hub_bloc.freezed.dart';
part 'admin_hub_event.dart';
part 'admin_hub_state.dart';

/// Cabecera del panel: estado del bloqueo global de la plataforma.
class AdminHubBloc extends Bloc<AdminHubEvent, AdminHubState> {
  AdminHubBloc({required this._getLockdown, required this._setLockdown})
    : super(const AdminHubState()) {
    on<AdminHubStarted>(_onStarted);
    on<AdminHubLockdownChanged>(_onLockdownChanged);
  }

  final GetLockdownUseCaseContract _getLockdown;
  final SetLockdownUseCaseContract _setLockdown;

  Future<void> _onStarted(
    AdminHubStarted event,
    Emitter<AdminHubState> emit,
  ) async {
    emit(state.copyWith(loading: true, loadError: null));
    final result = await _getLockdown();
    emit(
      result.fold(
        (lockdown) => state.copyWith(loading: false, lockdown: lockdown),
        (error) => state.copyWith(loading: false, loadError: error),
      ),
    );
  }

  Future<void> _onLockdownChanged(
    AdminHubLockdownChanged event,
    Emitter<AdminHubState> emit,
  ) async {
    emit(state.copyWith(updating: true, actionError: null));
    final result = await _setLockdown(active: event.active);
    emit(
      result.fold(
        (lockdown) => state.copyWith(updating: false, lockdown: lockdown),
        (error) => state.copyWith(updating: false, actionError: error),
      ),
    );
  }
}
