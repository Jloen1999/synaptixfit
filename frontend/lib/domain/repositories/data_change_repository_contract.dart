import '../enums/data_topic.dart';

/// Avisa de los cambios de datos hechos por cualquier pantalla, agrupados por
/// [DataTopic], para que las demás no se queden con datos viejos.
abstract interface class DataChangeRepositoryContract {
  Stream<Set<DataTopic>> watch();

  /// Anuncia un cambio que no hizo esta app sino el servidor (otra persona,
  /// por el canal en directo, ADR 0047).
  void publish(Set<DataTopic> topics);
}
