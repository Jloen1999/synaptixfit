import '../../models/result/app_result.dart';
import '../../models/training/today_adaptation.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Cómo se adapta hoy el entreno y por qué (sin empezar sesión).
abstract interface class GetTodayAdaptationUseCaseContract {
  Future<AppResult<TodayAdaptation>> call();
}

class GetTodayAdaptationUseCase implements GetTodayAdaptationUseCaseContract {
  const GetTodayAdaptationUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<TodayAdaptation>> call() => _repository.getTodayAdaptation();
}
