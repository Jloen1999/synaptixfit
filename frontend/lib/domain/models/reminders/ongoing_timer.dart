/// Notificación fija del Pomodoro en la barra del móvil mientras hay una fase
/// en marcha: con [endsAt] muestra la cuenta atrás; sin él (en pausa), el
/// texto de [body]. La compone la pantalla (textos) y la muestra el móvil.
class OngoingTimer {
  const OngoingTimer({
    required this.title,
    required this.body,
    required this.channelName,
    this.endsAt,
  });

  final String title;
  final String body;
  final DateTime? endsAt;

  /// Nombre del canal en los ajustes de Android.
  final String channelName;
}
