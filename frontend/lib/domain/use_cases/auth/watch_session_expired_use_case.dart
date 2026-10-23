import '../../models/result/result.dart';
import '../../repositories/auth_repository_contract.dart';

abstract interface class WatchSessionExpiredUseCaseContract {
  Stream<Unit> call();
}

class WatchSessionExpiredUseCase implements WatchSessionExpiredUseCaseContract {
  const WatchSessionExpiredUseCase(this._repository);

  final AuthRepositoryContract _repository;

  @override
  Stream<Unit> call() => _repository.watchSessionExpired();
}
