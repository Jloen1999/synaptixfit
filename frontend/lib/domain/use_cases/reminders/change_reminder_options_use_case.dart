import '../../models/reminders/reminder_options.dart';
import '../../models/result/app_result.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Guarda las opciones de los avisos del móvil: interruptores y cuándo llegan
/// (antelación, días antes, tareas de reto y resumen de la mañana, ADR 0035).
abstract interface class ChangeReminderOptionsUseCaseContract {
  Future<AppResult<ReminderOptions>> call(ReminderOptions options);
}

class ChangeReminderOptionsUseCase
    implements ChangeReminderOptionsUseCaseContract {
  const ChangeReminderOptionsUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<ReminderOptions>> call(ReminderOptions options) =>
      _repository.changeReminderOptions(options);
}
