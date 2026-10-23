import '../../models/planner/deadline.dart';
import '../../models/result/app_result.dart';
import '../../repositories/deadline_repository_contract.dart';

/// Entregas paginadas; [upcoming] = solo pendientes.
abstract interface class GetDeadlinesUseCaseContract {
  Future<AppResult<DeadlinePage>> call({
    bool upcoming = false,
    String? subjectId,
    int page = 0,
  });
}

class GetDeadlinesUseCase implements GetDeadlinesUseCaseContract {
  const GetDeadlinesUseCase(this._repository);

  final DeadlineRepositoryContract _repository;

  @override
  Future<AppResult<DeadlinePage>> call({
    bool upcoming = false,
    String? subjectId,
    int page = 0,
  }) => _repository.getDeadlines(
    upcoming: upcoming,
    subjectId: subjectId,
    page: page,
  );
}
