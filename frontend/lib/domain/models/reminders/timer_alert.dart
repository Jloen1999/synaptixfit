/// De qué temporizador es un aviso de fin de fase: cada uno tiene su propio
/// hueco, así el Pomodoro y la sala «Estudiar juntos» no se pisan.
enum TimerAlertSlot { pomodoro, studyRoom }

/// Aviso del sistema al terminar una fase del Pomodoro (o de la sala «Estudiar
/// juntos»), para que llegue aunque la app esté cerrada o en segundo plano. Lo
/// compone la pantalla (textos) y lo programa el móvil.
class TimerAlert {
  const TimerAlert({
    required this.at,
    required this.title,
    required this.body,
    required this.channelName,
    this.slot = TimerAlertSlot.pomodoro,
  });

  /// Hueco del aviso: uno nuevo sustituye solo al del mismo hueco.
  final TimerAlertSlot slot;

  final DateTime at;
  final String title;
  final String body;

  /// Nombre del canal de avisos del temporizador en los ajustes de Android.
  final String channelName;
}
