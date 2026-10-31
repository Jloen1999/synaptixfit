part of 'calendar_sync_bloc.dart';

@freezed
sealed class CalendarSyncEvent with _$CalendarSyncEvent {
  /// Carga el estado del enlace de suscripción.
  const factory CalendarSyncEvent.started() = CalendarSyncStarted;

  /// Crea el enlace (si había otro, deja de funcionar).
  const factory CalendarSyncEvent.feedCreated() = CalendarSyncFeedCreated;

  /// Desactiva el enlace.
  const factory CalendarSyncEvent.feedRevoked() = CalendarSyncFeedRevoked;

  /// Importa exámenes y entregas del calendario del Campus Virtual en [url].
  const factory CalendarSyncEvent.importRequested(String url) =
      CalendarSyncImportRequested;
}
