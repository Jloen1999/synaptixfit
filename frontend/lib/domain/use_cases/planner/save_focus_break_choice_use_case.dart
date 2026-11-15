import '../../models/planner/focus.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/focus_break_choice_repository_contract.dart';

/// Recuerda los descansos del Pomodoro elegidos para la próxima vez.
abstract interface class SaveFocusBreakChoiceUseCaseContract {
  Future<AppResult<Unit>> call(FocusBreakChoice choice);
}

/// Implementa [SaveFocusBreakChoiceUseCaseContract] con
/// [FocusBreakChoiceRepositoryContract].
class SaveFocusBreakChoiceUseCase
    implements SaveFocusBreakChoiceUseCaseContract {
  const SaveFocusBreakChoiceUseCase(this._repository);

  final FocusBreakChoiceRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(FocusBreakChoice choice) =>
      _repository.save(choice);
}
