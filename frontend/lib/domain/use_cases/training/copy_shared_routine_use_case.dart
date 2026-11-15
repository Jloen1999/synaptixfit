import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// «Copiar a mis rutinas» desde un enlace (ADR 0043): copia privada y sin
/// progreso.
abstract interface class CopySharedRoutineUseCaseContract {
  Future<AppResult<Routine>> call(String token);
}

class CopySharedRoutineUseCase implements CopySharedRoutineUseCaseContract {
  const CopySharedRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String token) =>
      _repository.copyShared(token);
}
