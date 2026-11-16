import '../../enums/guide_id.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/guide_progress_repository_contract.dart';

/// Si la guía de una pantalla debe salir: solo la primera vez de cada cuenta
/// en este teléfono (ADR 0049).
abstract interface class ShouldShowGuideUseCaseContract {
  Future<AppResult<bool>> call({
    required String accountId,
    required GuideId guide,
  });
}

/// Implementa [ShouldShowGuideUseCaseContract] con
/// [GuideProgressRepositoryContract].
class ShouldShowGuideUseCase implements ShouldShowGuideUseCaseContract {
  const ShouldShowGuideUseCase(this._repository);

  final GuideProgressRepositoryContract _repository;

  @override
  Future<AppResult<bool>> call({
    required String accountId,
    required GuideId guide,
  }) async {
    // Sin cuenta no se sabe de quién es la guía: mejor no enseñarla.
    if (accountId.isEmpty) return const Success(false);
    final seen = await _repository.seen(accountId);
    return seen.fold(
      (guides) => Success(!guides.contains(guide)),
      (error) => Failure(error),
    );
  }
}
