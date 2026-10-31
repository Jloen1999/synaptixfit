/// Aviso del sistema al terminar una fase del Pomodoro, para que llegue aunque
/// la app esté cerrada. Lo compone la pantalla (textos) y lo programa el móvil.
class TimerAlert {
  const TimerAlert({
    required this.at,
    required this.title,
    required this.body,
    required this.channelName,
  });

  final DateTime at;
  final String title;
  final String body;

  /// Nombre del canal de avisos del temporizador en los ajustes de Android.
  final String channelName;
}
