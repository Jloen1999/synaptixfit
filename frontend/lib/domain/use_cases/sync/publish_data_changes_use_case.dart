import '../../enums/data_topic.dart';
import '../../repositories/data_change_repository_contract.dart';

/// Anuncia a las pantallas un cambio hecho en el servidor por otra persona
/// (canal en directo, ADR 0047), igual que si lo hubiera hecho esta app.
abstract interface class PublishDataChangesUseCaseContract {
  void call(Set<DataTopic> topics);
}

/// Implementa [PublishDataChangesUseCaseContract] con
/// [DataChangeRepositoryContract].
class PublishDataChangesUseCase implements PublishDataChangesUseCaseContract {
  const PublishDataChangesUseCase(this._repository);

  final DataChangeRepositoryContract _repository;

  @override
  void call(Set<DataTopic> topics) {
    if (topics.isNotEmpty) _repository.publish(topics);
  }
}
