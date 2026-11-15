import '../../models/result/app_result.dart';
import '../../models/training/routine_share.dart';
import '../../repositories/routine_repository_contract.dart';

/// Resumen de la rutina de un enlace antes de copiarla (ADR 0043).
abstract interface class PreviewSharedRoutineUseCaseContract {
  Future<AppResult<SharedRoutinePreview>> call(String token);
}

class PreviewSharedRoutineUseCase
    implements PreviewSharedRoutineUseCaseContract {
  const PreviewSharedRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<SharedRoutinePreview>> call(String token) =>
      _repository.previewShared(token);
}
