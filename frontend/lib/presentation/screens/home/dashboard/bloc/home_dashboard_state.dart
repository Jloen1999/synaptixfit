part of 'home_dashboard_bloc.dart';

enum HomeDashboardStatus { loading, loaded, failure }

@freezed
abstract class HomeDashboardState with _$HomeDashboardState {
  const factory HomeDashboardState({
    @Default(HomeDashboardStatus.loading) HomeDashboardStatus status,
    HomeDashboard? dashboard,

    /// Error de la última carga. Con datos ya pintados se avisa con un SnackBar.
    AppError? error,

    /// Recarga en curso manteniendo los datos visibles.
    @Default(false) bool refreshing,
    @Default(<HomeDueReview>[]) List<HomeDueReview> dueReviews,

    /// Bloques y entregas de los próximos días (sin hoy), en orden.
    @Default(<HomeTodayEvent>[]) List<HomeTodayEvent> upcoming,

    @Default(0) int unreadNotifications,

    /// Configuración pendiente (aviso discreto); nulo si no se pudo leer.
    HomeSetup? setup,

    /// La página debe abrir `/onboarding` (efecto de un solo uso).
    @Default(false) bool onboardingRequired,

    /// La página debe abrir el paso «Permisos» (efecto de un solo uso).
    @Default(false) bool permissionsIntroRequired,

    /// Creando o recuperando la sesión de entrenamiento.
    @Default(false) bool startingTraining,

    /// Sesión que la página debe abrir (efecto de un solo uso).
    String? openSessionId,

    /// No se pudo empezar el entreno (efecto de un solo uso).
    AppError? trainingError,

    /// Empezar falló porque hay una sesión a medias (`SESSION_STALE_OPEN`): la
    /// página lleva a su tarjeta en vez de avisar sin salida (un solo uso).
    @Default(false) bool showUnfinished,

    /// Sesión a medias o eventos de ayer con una acción en curso.
    @Default(<String>{}) Set<String> actingIds,

    /// Descartado o quitado a la espera de su «Deshacer» (no se pinta). Las
    /// claves son `session:<id>` o `block:<id>` ([HomeDeferred]).
    @Default(<String>{}) Set<String> deferredKeys,

    /// Resultado de una acción de la sesión a medias o de lo de ayer (efecto
    /// de un solo uso).
    HomeActionNotice? actionNotice,

    /// Eventos y entregas que se están marcando o desmarcando.
    @Default(<String>{}) Set<String> completingIds,

    /// Resultado de marcar o desmarcar (efecto de un solo uso: aviso con
    /// «Deshacer»).
    HomeCompletionNotice? completionNotice,

    /// Lo último marcado o desmarcado que aún se puede deshacer con Ctrl+Z
    /// (no se limpia al mostrar el aviso, como [completionNotice]).
    HomeCompletionNoticeDone? lastUndoable,
  }) = _HomeDashboardState;
}

/// Qué pasó al marcar o desmarcar desde Inicio; la página lo dice con un
/// aviso que ofrece «Deshacer».
@freezed
sealed class HomeCompletionNotice with _$HomeCompletionNotice {
  /// Marcado ([completed]) o desmarcado; [xpDelta] es la XP ganada o
  /// devuelta (puede ser 0).
  const factory HomeCompletionNotice.done({
    required String id,
    required HomeEventKind kind,
    required bool completed,
    required int xpDelta,
  }) = HomeCompletionNoticeDone;

  const factory HomeCompletionNotice.failed(AppError error) =
      HomeCompletionNoticeFailed;
}

/// Claves de lo aplazado con «Deshacer»: una sesión descartada o un evento
/// quitado del calendario.
abstract final class HomeDeferred {
  static const _session = 'session:';
  static const _block = 'block:';

  static String session(String id) => '$_session$id';
  static String block(String id) => '$_block$id';

  static String? sessionId(String key) =>
      key.startsWith(_session) ? key.substring(_session.length) : null;
  static String? blockId(String key) =>
      key.startsWith(_block) ? key.substring(_block.length) : null;
}

/// Qué pasó con la sesión a medias o con lo de ayer; la página lo dice con
/// un aviso (y «Deshacer» o «Ver» cuando toca).
@freezed
sealed class HomeActionNotice with _$HomeActionNotice {
  /// Sesión guardada con lo hecho, en el día en que se hizo.
  const factory HomeActionNotice.sessionSaved() = HomeActionNoticeSessionSaved;

  /// Sesión quitada a la espera de «Deshacer» ([key] de [HomeDeferred]).
  const factory HomeActionNotice.sessionDiscarded(String key) =
      HomeActionNoticeSessionDiscarded;

  /// Día de rutina de ayer apuntado como hecho.
  const factory HomeActionNotice.logged() = HomeActionNoticeLogged;

  /// Evento llevado al día y la hora de [start].
  const factory HomeActionNotice.moved(DateTime start) = HomeActionNoticeMoved;

  /// Evento quitado a la espera de «Deshacer» ([key] de [HomeDeferred]).
  const factory HomeActionNotice.removed(String key) = HomeActionNoticeRemoved;

  const factory HomeActionNotice.failed(AppError error) =
      HomeActionNoticeFailed;
}
