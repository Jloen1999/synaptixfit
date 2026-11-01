import '../../models/academic/note_draft.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/note_draft_repository_contract.dart';

/// Guarda en el teléfono lo que se lleva escrito de un apunte.
abstract interface class SaveNoteDraftUseCaseContract {
  Future<AppResult<Unit>> call(NoteDraft draft);
}

class SaveNoteDraftUseCase implements SaveNoteDraftUseCaseContract {
  const SaveNoteDraftUseCase(this._repository);

  final NoteDraftRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(NoteDraft draft) => _repository.save(draft);
}
