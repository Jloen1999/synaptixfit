import '../../models/result/app_result.dart';
import '../../models/training/routine_draft.dart';
import '../../repositories/routine_repository_contract.dart';

/// Refina con IA una propuesta en edición.
abstract interface class RefineRoutineUseCaseContract {
  Future<AppResult<RoutineProposal>> call(RoutineProposal proposal);
}

class RefineRoutineUseCase implements RefineRoutineUseCaseContract {
  const RefineRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<RoutineProposal>> call(RoutineProposal proposal) =>
      _repository.refineRoutine(proposal);
}
