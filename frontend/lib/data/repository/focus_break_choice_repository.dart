import '../../domain/models/planner/focus.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/focus_break_choice_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/focus_break_choice_storage.dart';

/// Implementa [FocusBreakChoiceRepositoryContract] con
/// [FocusBreakChoiceStorage].
class FocusBreakChoiceRepository implements FocusBreakChoiceRepositoryContract {
  const FocusBreakChoiceRepository(this._storage);

  final FocusBreakChoiceStorage _storage;

  @override
  Future<AppResult<FocusBreakChoice>> load() =>
      RepositoryErrorHandler.guard(_storage.load);

  @override
  Future<AppResult<Unit>> save(FocusBreakChoice choice) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.save(choice);
        return unit;
      });
}
