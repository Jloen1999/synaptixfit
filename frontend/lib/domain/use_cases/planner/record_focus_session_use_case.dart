import '../../models/planner/focus.dart';
import '../../models/result/app_result.dart';
import '../../repositories/focus_repository_contract.dart';

/// Registra una fase Pomodoro terminada y devuelve la XP que concedió el
/// servidor junto con su estado (premiada, tope diario o sin derecho).
abstract interface class RecordFocusSessionUseCaseContract {
  Future<AppResult<FocusSessionResult>> call(FocusSessionRecord record);
}

class RecordFocusSessionUseCase implements RecordFocusSessionUseCaseContract {
  const RecordFocusSessionUseCase(this._repository);

  final FocusRepositoryContract _repository;

  @override
  Future<AppResult<FocusSessionResult>> call(FocusSessionRecord record) =>
      _repository.recordSession(record);
}
