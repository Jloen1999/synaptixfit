import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/weekly_email_status.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/profile/disable_weekly_email_use_case.dart';
import '../../../../../domain/use_cases/profile/enable_weekly_email_use_case.dart';
import '../../../../../domain/use_cases/profile/get_weekly_email_status_use_case.dart';

part 'weekly_email_bloc.freezed.dart';
part 'weekly_email_event.dart';
part 'weekly_email_state.dart';

/// Interruptor del resumen semanal por correo: se aplica al momento (sin el
/// botón «Guardar» de las preferencias). Activarlo sin cuenta de Google lo deja
/// pendiente hasta confirmar desde el correo (ADR 0022).
class WeeklyEmailBloc extends Bloc<WeeklyEmailEvent, WeeklyEmailState> {
  WeeklyEmailBloc({
    required this._getStatus,
    required this._enable,
    required this._disable,
  }) : super(const WeeklyEmailState()) {
    on<WeeklyEmailStarted>(_onStarted);
    on<WeeklyEmailToggled>(_onToggled);
  }

  final GetWeeklyEmailStatusUseCaseContract _getStatus;
  final EnableWeeklyEmailUseCaseContract _enable;
  final DisableWeeklyEmailUseCaseContract _disable;

  Future<void> _onStarted(
    WeeklyEmailStarted event,
    Emitter<WeeklyEmailState> emit,
  ) async {
    // Al reintentar tras un fallo, vuelve el esqueleto de carga.
    if (state.loadError != null) emit(state.copyWith(loadError: null));
    final result = await _getStatus();
    // Si no se puede leer, solo esta sección muestra el error: no bloquea el resto.
    emit(
      result.fold(
        (status) => state.copyWith(status: status),
        (error) => state.copyWith(loadError: error),
      ),
    );
  }

  Future<void> _onToggled(
    WeeklyEmailToggled event,
    Emitter<WeeklyEmailState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, error: null));
    if (event.enabled) {
      final result = await _enable();
      emit(
        result.fold(
          (status) => state.copyWith(busy: false, status: status),
          (error) => state.copyWith(busy: false, error: error),
        ),
      );
    } else {
      final result = await _disable();
      emit(switch (result) {
        Success() => state.copyWith(busy: false, status: WeeklyEmailStatus.off),
        Failure(:final error) => state.copyWith(busy: false, error: error),
      });
    }
  }
}
