import '../../models/challenges/challenge_references.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenge_references_repository_contract.dart';

/// Entregas y exámenes pendientes que vencen dentro del periodo del reto
/// ([from]-[to], por días; sin periodo, las próximas semanas), ordenados por
/// fecha. Los bloques de estudio no se vinculan: se asignan a una tarea desde
/// el editor de bloques (ADR 0028).
abstract interface class ListChallengeLinkTargetsUseCaseContract {
  Future<AppResult<List<ChallengeLinkOption>>> call({
    String? subjectId,
    DateTime? from,
    DateTime? to,
  });
}

class ListChallengeLinkTargetsUseCase
    implements ListChallengeLinkTargetsUseCaseContract {
  ListChallengeLinkTargetsUseCase(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Horizonte que se ofrece si no se indica el periodo.
  static const horizon = Duration(days: 28);

  final ChallengeReferencesRepositoryContract _repository;
  final DateTime Function() _now;

  @override
  Future<AppResult<List<ChallengeLinkOption>>> call({
    String? subjectId,
    DateTime? from,
    DateTime? to,
  }) async {
    final start = from ?? _now();
    final end = to ?? start.add(horizon);
    final result = await _repository.linkTargets(
      subjectId: subjectId,
      from: DateTime(start.year, start.month, start.day),
      to: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
    return result.map(
      // Entregas por fecha; los días de rutina (sin fecha) al final, en orden.
      (options) => [...options]
        ..sort((a, b) {
          final x = a.at;
          final y = b.at;
          if (x != null && y != null) return x.compareTo(y);
          if (x == null && y == null) return 0;
          return x == null ? 1 : -1;
        }),
    );
  }
}
