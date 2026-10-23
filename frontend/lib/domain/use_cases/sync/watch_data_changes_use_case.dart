import '../../enums/data_topic.dart';
import '../../repositories/data_change_repository_contract.dart';

/// Escucha los cambios de datos que afectan a alguno de los [topics] pedidos.
abstract interface class WatchDataChangesUseCaseContract {
  Stream<Set<DataTopic>> call({required Set<DataTopic> topics});
}

class WatchDataChangesUseCase implements WatchDataChangesUseCaseContract {
  const WatchDataChangesUseCase(this._repository);

  final DataChangeRepositoryContract _repository;

  @override
  Stream<Set<DataTopic>> call({required Set<DataTopic> topics}) => _repository
      .watch()
      .map((changed) => changed.intersection(topics))
      .where((relevant) => relevant.isNotEmpty);
}
