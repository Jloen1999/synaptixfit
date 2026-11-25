import '../../models/academic/material_sharing.dart';
import '../../models/result/app_result.dart';
import '../../repositories/share_repository_contract.dart';

/// «Compartir › Fuera de la app» (ADR 0064): abre el menú del sistema con el
/// archivo. `false` si la persona lo cierra sin compartir.
abstract interface class ShareFileOutsideUseCaseContract {
  Future<AppResult<bool>> call(MaterialFile file);
}

class ShareFileOutsideUseCase implements ShareFileOutsideUseCaseContract {
  const ShareFileOutsideUseCase(this._repository);

  final ShareRepositoryContract _repository;

  @override
  Future<AppResult<bool>> call(MaterialFile file) =>
      _repository.shareFile(file);
}
