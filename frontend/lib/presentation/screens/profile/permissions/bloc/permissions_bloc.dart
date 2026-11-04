import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/device_permission.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/profile/get_device_permission_status_use_case.dart';
import '../../../../../domain/use_cases/profile/mark_permissions_intro_seen_use_case.dart';
import '../../../../../domain/use_cases/profile/open_permission_settings_use_case.dart';
import '../../../../../domain/use_cases/profile/request_device_permission_use_case.dart';
import '../../../../../domain/use_cases/reminders/mark_reminders_offered_use_case.dart';
import '../../../../../domain/use_cases/reminders/set_device_reminders_enabled_use_case.dart';

part 'permissions_bloc.freezed.dart';
part 'permissions_event.dart';
part 'permissions_state.dart';

/// Estado de los permisos del móvil para el paso «Permisos», Ajustes ›
/// Permisos y la hoja que se abre justo antes de usar la cámara o los avisos.
/// Las notificaciones se conceden activando los recordatorios del móvil: así
/// pedir el permiso también los enciende y no se vuelven a ofrecer.
class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  PermissionsBloc({
    required this._getStatus,
    required this._request,
    required this._openSettings,
    required this._markIntroSeen,
    required this._setRemindersEnabled,
    required this._markRemindersOffered,
  }) : super(const PermissionsState()) {
    on<PermissionsStarted>(_onStarted);
    on<PermissionsRequested>(_onRequested);
    on<PermissionsSettingsOpened>(_onSettingsOpened);
    on<PermissionsResumed>(_onResumed);
    on<PermissionsSkipped>(
      (event, emit) =>
          emit(state.copyWith(skipped: {...state.skipped, event.permission})),
    );
    on<PermissionsIntroFinished>(_onIntroFinished);
  }

  final GetDevicePermissionStatusUseCaseContract _getStatus;
  final RequestDevicePermissionUseCaseContract _request;
  final OpenPermissionSettingsUseCaseContract _openSettings;
  final MarkPermissionsIntroSeenUseCaseContract _markIntroSeen;
  final SetDeviceRemindersEnabledUseCaseContract _setRemindersEnabled;
  final MarkRemindersOfferedUseCaseContract _markRemindersOffered;

  Future<void> _onStarted(
    PermissionsStarted event,
    Emitter<PermissionsState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null, shown: event.permissions));
    await _refresh(emit);
  }

  Future<void> _onResumed(
    PermissionsResumed event,
    Emitter<PermissionsState> emit,
  ) async {
    // Al volver de los ajustes del sistema el permiso puede haber cambiado.
    if (state.shown.isEmpty) return;
    await _refresh(emit);
  }

  Future<void> _onRequested(
    PermissionsRequested event,
    Emitter<PermissionsState> emit,
  ) async {
    final permission = event.permission;
    emit(state.copyWith(busy: permission, error: null));
    if (permission == DevicePermission.notifications) {
      final enabled = await _setRemindersEnabled(true);
      await _markRemindersOffered();
      if (enabled case Failure(:final error)) {
        emit(state.copyWith(busy: null, error: error));
        return;
      }
      final status = await _getStatus(permission);
      _store(emit, permission, status);
      return;
    }
    _store(emit, permission, await _request(permission));
  }

  Future<void> _onSettingsOpened(
    PermissionsSettingsOpened event,
    Emitter<PermissionsState> emit,
  ) async {
    final opened = await _openSettings(event.permission);
    if (opened case Failure(:final error)) {
      emit(state.copyWith(error: error));
      return;
    }
    // En las alarmas exactas, la pantalla del sistema vuelve sola: se
    // comprueba ya; en el resto, al volver a la app ([PermissionsResumed]).
    await _refresh(emit);
  }

  Future<void> _onIntroFinished(
    PermissionsIntroFinished event,
    Emitter<PermissionsState> emit,
  ) async {
    await _markIntroSeen();
    emit(state.copyWith(introFinished: true));
  }

  Future<void> _refresh(Emitter<PermissionsState> emit) async {
    final statuses = {...state.statuses};
    for (final permission in state.shown) {
      final status = await _getStatus(permission);
      if (status case Failure(:final error)) {
        emit(state.copyWith(loading: false, error: error));
        return;
      }
      statuses[permission] = status.valueOrNull!;
    }
    emit(state.copyWith(loading: false, busy: null, statuses: statuses));
  }

  void _store(
    Emitter<PermissionsState> emit,
    DevicePermission permission,
    Result<DevicePermissionStatus, AppError> status,
  ) {
    switch (status) {
      case Success(:final value):
        emit(
          state.copyWith(
            busy: null,
            statuses: {...state.statuses, permission: value},
            requested: {...state.requested, permission},
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(busy: null, error: error));
    }
  }
}
