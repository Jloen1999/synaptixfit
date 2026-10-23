import '../../models/result/app_result.dart';
import '../../repositories/home_repository_contract.dart';

/// Número de notificaciones sin leer para la campana del inicio.
abstract interface class GetHomeUnreadCountUseCaseContract {
  Future<AppResult<int>> call();
}

class GetHomeUnreadCountUseCase implements GetHomeUnreadCountUseCaseContract {
  const GetHomeUnreadCountUseCase(this._repository);

  final HomeRepositoryContract _repository;

  @override
  Future<AppResult<int>> call() => _repository.getUnreadNotificationsCount();
}
