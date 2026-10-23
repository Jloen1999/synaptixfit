import '../../models/result/app_result.dart';
import '../../models/training/session_history.dart';
import '../../repositories/training_history_repository_contract.dart';

/// Mejor marca actual de cada ejercicio, de la más reciente a la más antigua.
abstract interface class GetPersonalRecordsUseCaseContract {
  Future<AppResult<List<PersonalRecord>>> call();
}

class GetPersonalRecordsUseCase implements GetPersonalRecordsUseCaseContract {
  const GetPersonalRecordsUseCase(this._repository);

  final TrainingHistoryRepositoryContract _repository;

  @override
  Future<AppResult<List<PersonalRecord>>> call() =>
      _repository.getPersonalRecords();
}
