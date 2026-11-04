import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Retira el permiso del registro diario. El servidor borra el de hoy y, con
/// [deleteRecords], también los anteriores.
abstract interface class WithdrawHealthConsentUseCaseContract {
  Future<AppResult<Unit>> call({required bool deleteRecords});
}

class WithdrawHealthConsentUseCase
    implements WithdrawHealthConsentUseCaseContract {
  const WithdrawHealthConsentUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required bool deleteRecords}) =>
      _repository.withdrawHealthConsent(deleteRecords: deleteRecords);
}
