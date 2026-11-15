import '../../../models/result/app_result.dart';
import '../../../models/social/together_live.dart';
import '../../../repositories/together_live_repository_contract.dart';

/// Escucha el canal en directo de «Con amigos» (ADR 0047) mientras haya alguien
/// suscrito.
abstract interface class WatchTogetherLiveUseCaseContract {
  Stream<AppResult<TogetherLiveSignal>> call();
}

/// Implementa [WatchTogetherLiveUseCaseContract] con
/// [TogetherLiveRepositoryContract].
class WatchTogetherLiveUseCase implements WatchTogetherLiveUseCaseContract {
  const WatchTogetherLiveUseCase(this._repository);

  final TogetherLiveRepositoryContract _repository;

  @override
  Stream<AppResult<TogetherLiveSignal>> call() => _repository.watch();
}
