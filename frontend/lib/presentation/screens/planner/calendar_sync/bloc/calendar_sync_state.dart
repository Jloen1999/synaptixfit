part of 'calendar_sync_bloc.dart';

enum CalendarSyncStatus { loading, ready, failure }

/// Acción en curso sobre el enlace (cada botón muestra su propia carga).
enum CalendarFeedAction { creating, revoking }

@freezed
abstract class CalendarSyncState with _$CalendarSyncState {
  const factory CalendarSyncState({
    @Default(CalendarSyncStatus.loading) CalendarSyncStatus status,
    @Default(CalendarFeedStatus()) CalendarFeedStatus feed,

    /// Enlace recién creado: solo se puede ver ahora.
    CalendarFeedLink? link,
    CalendarFeedAction? feedAction,

    /// Sube con cada desactivación correcta (la página lo anuncia).
    @Default(0) int revokedCount,
    @Default(false) bool importing,

    /// Se pulsó «Importar» con el campo vacío.
    @Default(false) bool urlMissing,

    /// Resultado de la última importación del Campus Virtual.
    IcsImportResult? importResult,

    /// Error de la importación: se muestra junto al campo.
    AppError? importError,

    /// Error al cargar (pantalla de error) y error del enlace (aviso).
    AppError? error,
    AppError? actionError,
    @Default(0) int actionErrorId,
  }) = _CalendarSyncState;

  const CalendarSyncState._();

  bool get feedBusy => feedAction != null;
}
