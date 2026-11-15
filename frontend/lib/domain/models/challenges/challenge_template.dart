import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/challenge_difficulty.dart';
import '../../enums/challenge_type.dart';
import 'challenge_rule.dart';

part 'challenge_template.freezed.dart';

/// Plantilla de reto productivo (ADR 0043). «Empezar este reto» crea un reto
/// propio que el servidor cuenta solo. [running]: ya hay uno suyo en marcha.
@freezed
abstract class ChallengeTemplate with _$ChallengeTemplate {
  const factory ChallengeTemplate({
    required String id,
    required String code,
    required String title,
    @Default('') String goal,
    required ChallengeType type,
    required ChallengeDifficulty difficulty,
    required int days,
    required ChallengeRule rule,
    @Default(false) bool running,
  }) = _ChallengeTemplate;
}
