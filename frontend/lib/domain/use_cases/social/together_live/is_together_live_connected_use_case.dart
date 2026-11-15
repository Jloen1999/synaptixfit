import '../../../repositories/together_live_repository_contract.dart';

/// Si el canal en directo está conectado (ADR 0047). Con él, las pantallas de
/// «Con amigos» consultan más despacio: la consulta queda solo de respaldo.
abstract interface class IsTogetherLiveConnectedUseCaseContract {
  bool call();
}

/// Implementa [IsTogetherLiveConnectedUseCaseContract] con
/// [TogetherLiveRepositoryContract].
class IsTogetherLiveConnectedUseCase
    implements IsTogetherLiveConnectedUseCaseContract {
  const IsTogetherLiveConnectedUseCase(this._repository);

  final TogetherLiveRepositoryContract _repository;

  @override
  bool call() => _repository.connected;
}
