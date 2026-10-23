import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/use_cases/reminders/get_device_reminders_status_use_case.dart';
import '../../../../../domain/use_cases/reminders/set_device_reminders_enabled_use_case.dart';

part 'device_reminders_bloc.freezed.dart';
part 'device_reminders_event.dart';
part 'device_reminders_state.dart';

/// Interruptor «Recordatorios en este móvil» de la pantalla de notificaciones.
/// Es local al teléfono y se guarda al momento, a diferencia de las
/// preferencias de la cuenta (`NotificationSettingsBloc`). `started` se repite
/// al volver a la app para ver si el permiso del sistema ha cambiado.
class DeviceRemindersBloc
    extends Bloc<DeviceRemindersEvent, DeviceRemindersState> {
  DeviceRemindersBloc({required this._getStatus, required this._setEnabled})
    : super(const DeviceRemindersState()) {
    on<DeviceRemindersStarted>(_onStarted);
    on<DeviceRemindersToggled>(_onToggled);
  }

  final GetDeviceRemindersStatusUseCaseContract _getStatus;
  final SetDeviceRemindersEnabledUseCaseContract _setEnabled;

  Future<void> _onStarted(
    DeviceRemindersStarted event,
    Emitter<DeviceRemindersState> emit,
  ) async {
    final status = (await _getStatus()).valueOrNull;
    final granted = status?.permissionGranted ?? true;
    emit(
      state.copyWith(
        loaded: true,
        supported: status?.supported ?? false,
        enabled: status?.enabled ?? false,
        // Se mantiene la fila del permiso si estaban activados aquí (y se
        // retiró en el sistema) o si se acaba de negar y sigue negado.
        permissionDenied:
            !granted && ((status?.enabled ?? false) || state.permissionDenied),
      ),
    );
  }

  Future<void> _onToggled(
    DeviceRemindersToggled event,
    Emitter<DeviceRemindersState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, permissionDenied: false, error: null));
    final result = await _setEnabled(event.enabled);
    emit(
      result.fold(
        (enabled) => state.copyWith(
          busy: false,
          enabled: enabled,
          permissionDenied: event.enabled && !enabled,
        ),
        (error) => state.copyWith(busy: false, error: error),
      ),
    );
  }
}
