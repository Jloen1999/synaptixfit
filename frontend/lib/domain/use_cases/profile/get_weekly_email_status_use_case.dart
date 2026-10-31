import '../../enums/weekly_email_status.dart';
import '../../models/result/app_result.dart';
import '../../repositories/notification_preferences_repository_contract.dart';

/// Estado del resumen semanal por correo.
abstract interface class GetWeeklyEmailStatusUseCaseContract {
  Future<AppResult<WeeklyEmailStatus>> call();
}

class GetWeeklyEmailStatusUseCase
    implements GetWeeklyEmailStatusUseCaseContract {
  const GetWeeklyEmailStatusUseCase(this._repository);

  final NotificationPreferencesRepositoryContract _repository;

  @override
  Future<AppResult<WeeklyEmailStatus>> call() => _repository.getWeeklyEmail();
}
