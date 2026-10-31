import '../../enums/weekly_email_status.dart';
import '../../models/result/app_result.dart';
import '../../repositories/notification_preferences_repository_contract.dart';

/// Activa el resumen semanal por correo en el idioma de la app. Sin cuenta de
/// Google queda pendiente hasta confirmar desde el correo.
abstract interface class EnableWeeklyEmailUseCaseContract {
  Future<AppResult<WeeklyEmailStatus>> call();
}

class EnableWeeklyEmailUseCase implements EnableWeeklyEmailUseCaseContract {
  const EnableWeeklyEmailUseCase(this._repository);

  final NotificationPreferencesRepositoryContract _repository;

  @override
  Future<AppResult<WeeklyEmailStatus>> call() =>
      _repository.enableWeeklyEmail();
}
