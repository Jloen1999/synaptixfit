import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/challenge_rule_kind.dart';

part 'challenge_rule.freezed.dart';

/// Regla con la que el servidor cuenta solo un reto (ADR 0043): «[perUnit] de
/// [metric] cada [unit], [target] veces». [met] es lo ya cumplido (0 en una
/// plantilla). [privateOnly]: sale del registro diario y nunca se comparte.
@freezed
abstract class ChallengeRule with _$ChallengeRule {
  const factory ChallengeRule({
    required ChallengeRuleMetric metric,
    required ChallengeRuleUnit unit,
    required int perUnit,
    required int target,
    @Default(false) bool weekdaysOnly,
    @Default(0) int met,
    @Default(false) bool privateOnly,
  }) = _ChallengeRule;
}
