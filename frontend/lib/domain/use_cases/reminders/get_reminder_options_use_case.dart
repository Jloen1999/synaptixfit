import '../../models/reminders/reminder_options.dart';
import '../../models/result/app_result.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Avisos opcionales del móvil encendidos (racha, registro diario, clases).
abstract interface class GetReminderOptionsUseCaseContract {
  Future<AppResult<ReminderOptions>> call();
}

class GetReminderOptionsUseCase implements GetReminderOptionsUseCaseContract {
  const GetReminderOptionsUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<ReminderOptions>> call() => _repository.getReminderOptions();
}
