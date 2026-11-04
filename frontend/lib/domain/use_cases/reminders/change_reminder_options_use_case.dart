import '../../models/reminders/reminder_options.dart';
import '../../models/result/app_result.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Enciende o apaga los avisos opcionales del móvil.
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
