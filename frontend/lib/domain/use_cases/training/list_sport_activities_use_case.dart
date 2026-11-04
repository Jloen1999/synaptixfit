import '../../models/result/app_result.dart';
import '../../models/training/sport_activity.dart';
import '../../models/training/training_page.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Partidos y actividades hechos fuera de las rutinas, para el historial.
abstract interface class ListSportActivitiesUseCaseContract {
  Future<AppResult<TrainingPage<SportActivity>>> call({
    int page = 0,
    int size = 20,
  });
}

class ListSportActivitiesUseCase implements ListSportActivitiesUseCaseContract {
  const ListSportActivitiesUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingPage<SportActivity>>> call({
    int page = 0,
    int size = 20,
  }) => _repository.listSportActivities(page: page, size: size);
}
