import '../enums/data_topic.dart';

/// Avisa de los cambios de datos hechos por cualquier pantalla, agrupados por
/// [DataTopic], para que las demás no se queden con datos viejos.
abstract interface class DataChangeRepositoryContract {
  Stream<Set<DataTopic>> watch();
}
