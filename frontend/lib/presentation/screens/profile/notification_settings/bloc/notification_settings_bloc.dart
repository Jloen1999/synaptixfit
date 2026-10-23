import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/profile/notification_category.dart';
import '../../../../../domain/enums/profile/notification_mode.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/profile/notification_preferences.dart';
import '../../../../../domain/use_cases/profile/get_notification_preferences_use_case.dart';
import '../../../../../domain/use_cases/profile/update_notification_preferences_use_case.dart';

part 'notification_settings_bloc.freezed.dart';
part 'notification_settings_event.dart';
part 'notification_settings_state.dart';

/// Preferencias de notificaciones: se editan en memoria y se guardan juntas.
class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  NotificationSettingsBloc({
    required this._getPreferences,
    required this._updatePreferences,
  }) : super(const NotificationSettingsState()) {
    on<NotificationSettingsStarted>(_onStarted);
    on<NotificationSettingsCategoryToggled>(_onCategoryToggled);
    on<NotificationSettingsQuietHoursChanged>(
      (e, emit) => _edit(
        emit,
        (p) => p.copyWith(quietHoursStart: e.start, quietHoursEnd: e.end),
      ),
    );
    on<NotificationSettingsQuietHoursCleared>(
      (_, emit) => _edit(
        emit,
        (p) => p.copyWith(quietHoursStart: null, quietHoursEnd: null),
      ),
    );
    on<NotificationSettingsDailyLimitChanged>(
      (e, emit) =>
          _edit(emit, (p) => p.copyWith(dailyLimit: e.limit.clamp(0, 50))),
    );
    on<NotificationSettingsModeChanged>(
      (e, emit) => _edit(emit, (p) => p.copyWith(mode: e.mode)),
    );
    on<NotificationSettingsSaveRequested>(_onSave);
  }

  final GetNotificationPreferencesUseCaseContract _getPreferences;
  final UpdateNotificationPreferencesUseCaseContract _updatePreferences;

  Future<void> _onStarted(
    NotificationSettingsStarted event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(
      state.copyWith(status: NotificationSettingsStatus.loading, error: null),
    );
    final result = await _getPreferences();
    emit(
      result.fold(
        (preferences) => state.copyWith(
          status: NotificationSettingsStatus.ready,
          preferences: preferences,
          dirty: false,
        ),
        (error) => state.copyWith(
          status: NotificationSettingsStatus.failure,
          error: error,
        ),
      ),
    );
  }

  void _onCategoryToggled(
    NotificationSettingsCategoryToggled event,
    Emitter<NotificationSettingsState> emit,
  ) => _edit(emit, (p) {
    final categories = {...p.activeCategories};
    if (!categories.remove(event.category)) categories.add(event.category);
    return p.copyWith(activeCategories: categories);
  });

  void _edit(
    Emitter<NotificationSettingsState> emit,
    NotificationPreferences Function(NotificationPreferences) change,
  ) {
    final current = state.preferences;
    if (current == null) return;
    emit(
      state.copyWith(
        preferences: change(current),
        dirty: true,
        saved: false,
        actionError: null,
      ),
    );
  }

  Future<void> _onSave(
    NotificationSettingsSaveRequested event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final current = state.preferences;
    if (current == null || state.saving) return;
    emit(state.copyWith(saving: true, saved: false, actionError: null));
    final result = await _updatePreferences(current);
    emit(
      result.fold(
        (preferences) => state.copyWith(
          saving: false,
          saved: true,
          dirty: false,
          preferences: preferences,
        ),
        (error) => state.copyWith(saving: false, actionError: error),
      ),
    );
  }
}
