import '../../models/result/app_result.dart';
import '../../models/training/load_suggestion.dart';
import '../../repositories/training_repository_contract.dart';

/// Propuestas de carga de hoy para los ejercicios de una sesión en curso.
abstract interface class GetLoadSuggestionsUseCaseContract {
  Future<AppResult<List<LoadSuggestion>>> call(String sessionId);
}

class GetLoadSuggestionsUseCase implements GetLoadSuggestionsUseCaseContract {
  const GetLoadSuggestionsUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<List<LoadSuggestion>>> call(String sessionId) =>
      _repository.getLoadSuggestions(sessionId);
}
