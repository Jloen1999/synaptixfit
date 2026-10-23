import '../../enums/challenge_type.dart';
import '../../enums/milestone_condition.dart';
import '../../errors/app_error.dart';
import 'challenge_draft.dart';

/// Motivo por el que un borrador de reto no es válido (mismas reglas que el servidor).
enum ChallengeDraftIssue {
  titleTooShort(null),
  invalidDates('CHALLENGE_INVALID_DATES'),
  tooManyMilestones('CHALLENGE_TOO_MANY_MILESTONES'),
  milestoneTitleTooShort(null),
  weightsIncomplete('MILESTONE_WEIGHTS_INVALID'),
  weightOutOfRange('MILESTONE_WEIGHTS_INVALID'),
  weightsSum('MILESTONE_WEIGHTS_INVALID'),
  dependencyInvalid('MILESTONE_DEPENDENCY_INVALID'),
  dependencyCycle('MILESTONE_DEPENDENCY_INVALID'),
  conditionInvalid('MILESTONE_DEPENDENCY_INVALID'),
  attachmentConflict('MILESTONE_ATTACHMENT_CONFLICT'),
  sessionTargetInvalid(null);

  const ChallengeDraftIssue(this.code);

  /// `code` de error equivalente del catálogo de la API (`null` = VALIDATION_ERROR).
  final String? code;

  /// Error de dominio equivalente.
  AppError get asError {
    final c = code;
    return c == null ? const AppError.validation() : AppError.business(c);
  }
}

/// Validación local de retos y tareas antes de enviarlos al servidor.
abstract final class ChallengeDraftValidator {
  static const titleMin = 5;
  static const titleMax = 80;
  static const milestoneTitleMin = 3;
  static const maxMilestones = 12;
  static const sessionTargetMin = 1;
  static const sessionTargetMax = 365;

  /// Margen admitido en la suma de pesos (p. ej. 3 × 33,33 = 99,99).
  static const weightTolerance = 0.1;

  static ChallengeDraftIssue? validate(ChallengeDraft draft) {
    final title = draft.title.trim();
    if (title.length < titleMin || title.length > titleMax) {
      return ChallengeDraftIssue.titleTooShort;
    }
    final start = draft.startAt;
    if (start != null && !draft.endAt.isAfter(start)) {
      return ChallengeDraftIssue.invalidDates;
    }
    final target = draft.sessionTarget;
    if (target != null &&
        (!isValidSessionTarget(target) ||
            draft.type == ChallengeType.academic)) {
      return ChallengeDraftIssue.sessionTargetInvalid;
    }
    return validateMilestones(draft.milestones);
  }

  static bool isValidSessionTarget(int target) =>
      target >= sessionTargetMin && target <= sessionTargetMax;

  static ChallengeDraftIssue? validateMilestones(
    List<MilestoneDraft> milestones,
  ) {
    if (milestones.length > maxMilestones) {
      return ChallengeDraftIssue.tooManyMilestones;
    }
    for (final m in milestones) {
      final length = m.title.trim().length;
      if (length < milestoneTitleMin || length > titleMax) {
        return ChallengeDraftIssue.milestoneTitleTooShort;
      }
      if (m.noteId != null && m.fileId != null) {
        return ChallengeDraftIssue.attachmentConflict;
      }
    }
    return _validateWeights(milestones) ?? _validateDependencies(milestones);
  }

  /// Suma de los pesos indicados (para mostrarla mientras se editan).
  static double weightSum(Iterable<double?> weights) =>
      weights.fold(0, (sum, w) => sum + (w ?? 0));

  /// Pesos automáticos: reparte 100 a partes iguales (el último absorbe el resto).
  static List<double> autoWeights(int count) {
    if (count == 0) return const [];
    final base = (10000 / count).floor() / 100;
    return [
      for (var i = 0; i < count - 1; i++) base,
      ((100 - base * (count - 1)) * 100).round() / 100,
    ];
  }

  static ChallengeDraftIssue? _validateWeights(List<MilestoneDraft> drafts) {
    final given = drafts.where((d) => d.weight != null).length;
    if (given == 0) return null;
    if (given != drafts.length) return ChallengeDraftIssue.weightsIncomplete;
    for (final d in drafts) {
      final w = d.weight!;
      if (!(w > 0) || w > 100) return ChallengeDraftIssue.weightOutOfRange;
    }
    final sum = weightSum(drafts.map((d) => d.weight));
    return (sum - 100).abs() > weightTolerance
        ? ChallengeDraftIssue.weightsSum
        : null;
  }

  static ChallengeDraftIssue? _validateDependencies(
    List<MilestoneDraft> drafts,
  ) {
    final n = drafts.length;
    for (var i = 0; i < n; i++) {
      final d = drafts[i];
      final seen = <int>{};
      for (final dep in d.dependsOn) {
        if (dep < 0 || dep >= n || dep == i || !seen.add(dep)) {
          return ChallengeDraftIssue.dependencyInvalid;
        }
      }
      if (d.condition == MilestoneCondition.xOfY) {
        final required = d.conditionN ?? 1;
        if (required < 1 || required > d.dependsOn.length) {
          return ChallengeDraftIssue.conditionInvalid;
        }
      }
    }
    return hasCycle(drafts.map((d) => d.dependsOn).toList())
        ? ChallengeDraftIssue.dependencyCycle
        : null;
  }

  /// `true` si el grafo de dependencias (por posiciones) contiene un ciclo.
  static bool hasCycle(List<List<int>> graph) {
    final color = List.filled(graph.length, 0);
    bool visit(int node) {
      color[node] = 1;
      for (final next in graph[node]) {
        if (next < 0 || next >= graph.length) continue;
        if (color[next] == 1 || (color[next] == 0 && visit(next))) return true;
      }
      color[node] = 2;
      return false;
    }

    for (var i = 0; i < graph.length; i++) {
      if (color[i] == 0 && visit(i)) return true;
    }
    return false;
  }
}
