import '../../enums/device_permission.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/device_permissions_repository_contract.dart';

/// ¿Hay que enseñar el paso «Permisos»? Una vez por dispositivo, y solo si
/// algún permiso existe en esta plataforma y aún no está concedido.
abstract interface class IsPermissionsIntroPendingUseCaseContract {
  Future<AppResult<bool>> call();
}

class IsPermissionsIntroPendingUseCase
    implements IsPermissionsIntroPendingUseCaseContract {
  const IsPermissionsIntroPendingUseCase(this._repository);

  final DevicePermissionsRepositoryContract _repository;

  @override
  Future<AppResult<bool>> call() async {
    final seen = await _repository.introSeen();
    if (seen case Failure(:final error)) return Failure(error);
    if (seen.valueOrNull ?? true) return const Success(false);
    for (final permission in DevicePermission.values) {
      final status = await _repository.status(permission);
      if (status case Failure(:final error)) return Failure(error);
      if (!(status.valueOrNull?.usable ?? true)) return const Success(true);
    }
    return const Success(false);
  }
}
