/// Áreas de datos que una acción del usuario puede cambiar. Las pantallas se
/// suscriben a las que muestran para refrescarse cuando otra pantalla las toca.
enum DataTopic {
  training,
  academic,
  planner,
  challenges,
  gamification,
  profile,
  social,

  /// Una sala de estudio cambió en el servidor (canal en directo, ADR 0047).
  studyRoom,

  /// Un entreno juntos cambió en el servidor: alguien entró, empezó, pausó o
  /// apuntó una serie (canal en directo, ADR 0047).
  workoutTogether;

  /// Los que solo llegan por el canal en directo: cambian a menudo y solo
  /// interesan a las pantallas de «Con amigos» y la sesión en vivo.
  static const live = {studyRoom, workoutTogether};
}
