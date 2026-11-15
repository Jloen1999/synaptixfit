import '../../enums/data_topic.dart';

/// Qué anuncia el canal en directo de «Con amigos» (ADR 0047).
enum TogetherLiveTopic {
  /// El canal acaba de abrirse (todavía sin cambios).
  connected,
  studyRoom,
  workout,

  /// La lista de «Con amigos» (p. ej. una invitación nueva).
  together,
}

/// Aviso sin datos del canal en directo: «cambió esta sala o este entreno».
/// Quien lo recibe vuelve a leer por la API de siempre.
class TogetherLiveSignal {
  const TogetherLiveSignal(this.topic, [this.id]);

  final TogetherLiveTopic topic;

  /// La sala o el entreno que cambió (nulo en [TogetherLiveTopic.connected]).
  final String? id;

  /// Qué pantallas tienen que volver a leer.
  Set<DataTopic> get dataTopics => switch (topic) {
    TogetherLiveTopic.connected => const {},
    // Solo los temas en directo: `social` haría que cada serie de un amigo
    // reprogramara los recordatorios y recargara Progreso en todo el grupo.
    TogetherLiveTopic.studyRoom => const {DataTopic.studyRoom},
    TogetherLiveTopic.workout => const {DataTopic.workoutTogether},
    TogetherLiveTopic.together => const {DataTopic.social},
  };

  @override
  bool operator ==(Object other) =>
      other is TogetherLiveSignal && other.topic == topic && other.id == id;

  @override
  int get hashCode => Object.hash(topic, id);

  @override
  String toString() => 'TogetherLiveSignal($topic, $id)';
}
