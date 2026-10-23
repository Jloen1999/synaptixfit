import '../../models/challenges/challenge_references.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenge_references_repository_contract.dart';

/// Entregas/exámenes pendientes y bloques de estudio de las próximas semanas
/// a los que se puede vincular un reto o tarea, ordenados por fecha.
abstract interface class ListChallengeLinkTargetsUseCaseContract {
  Future<AppResult<List<ChallengeLinkOption>>> call({String? subjectId});
}

class ListChallengeLinkTargetsUseCase
    implements ListChallengeLinkTargetsUseCaseContract {
  ListChallengeLinkTargetsUseCase(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Horizonte de bloques futuros que se ofrecen.
  static const horizon = Duration(days: 28);

  final ChallengeReferencesRepositoryContract _repository;
  final DateTime Function() _now;

  @override
  Future<AppResult<List<ChallengeLinkOption>>> call({String? subjectId}) async {
    final from = _now();
    final result = await _repository.linkTargets(
      subjectId: subjectId,
      from: from,
      to: from.add(horizon),
    );
    return result.map(
      (options) => [...options]..sort((a, b) => a.at.compareTo(b.at)),
    );
  }
}
