import '../../models/planner/focus.dart';
import '../../models/result/app_result.dart';
import '../../repositories/focus_break_choice_repository_contract.dart';

/// Descansos del Pomodoro elegidos la última vez (vacío: los recomendados).
abstract interface class LoadFocusBreakChoiceUseCaseContract {
  Future<AppResult<FocusBreakChoice>> call();
}

/// Implementa [LoadFocusBreakChoiceUseCaseContract] con
/// [FocusBreakChoiceRepositoryContract].
class LoadFocusBreakChoiceUseCase
    implements LoadFocusBreakChoiceUseCaseContract {
  const LoadFocusBreakChoiceUseCase(this._repository);

  final FocusBreakChoiceRepositoryContract _repository;

  @override
  Future<AppResult<FocusBreakChoice>> call() => _repository.load();
}
