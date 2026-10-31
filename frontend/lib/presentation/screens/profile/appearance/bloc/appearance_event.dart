part of 'appearance_bloc.dart';

@freezed
sealed class AppearanceEvent with _$AppearanceEvent {
  /// Lee la apariencia guardada en el dispositivo.
  const factory AppearanceEvent.started() = AppearanceStarted;

  const factory AppearanceEvent.changed(AppearanceMode mode) =
      AppearanceChanged;
}
