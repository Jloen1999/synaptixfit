import 'package:flutter/material.dart';

import '../../../../../domain/enums/together_enums.dart';
import '../../../../../domain/models/challenges/challenge_rule.dart';
import '../../../../../domain/models/social/together.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../challenges/widgets/challenge_labels.dart';

/// Emoji y nombre de cada reacción fija (ADR 0044). El emoji es igual en todos
/// los idiomas; el nombre es para el lector de pantalla.
extension TogetherReactionLabel on TogetherReaction {
  String get emoji => switch (this) {
    TogetherReaction.clap => '\u{1F44F}',
    TogetherReaction.fire => '\u{1F525}',
    TogetherReaction.muscle => '\u{1F4AA}',
    TogetherReaction.heart => '\u{2764}\u{FE0F}',
  };

  String label(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      TogetherReaction.clap => l10n.togetherReactionClap,
      TogetherReaction.fire => l10n.togetherReactionFire,
      TogetherReaction.muscle => l10n.togetherReactionMuscle,
      TogetherReaction.heart => l10n.togetherReactionHeart,
    };
  }
}

/// Emoji y nombre de cada reacción fija de una sala de estudio (ADR 0045).
extension StudyRoomReactionLabel on StudyRoomReaction {
  String get emoji => switch (this) {
    StudyRoomReaction.clap => '\u{1F44F}',
    StudyRoomReaction.fire => '\u{1F525}',
    StudyRoomReaction.muscle => '\u{1F4AA}',
    StudyRoomReaction.coffee => '\u{2615}',
  };

  String label(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      StudyRoomReaction.clap => l10n.togetherReactionClap,
      StudyRoomReaction.fire => l10n.togetherReactionFire,
      StudyRoomReaction.muscle => l10n.togetherReactionMuscle,
      StudyRoomReaction.coffee => l10n.togetherReactionCoffee,
    };
  }
}

/// Nombre de cada modo de reto con amigos.
extension FriendChallengeModeLabel on FriendChallengeMode {
  String label(BuildContext context) => switch (this) {
    FriendChallengeMode.cooperative =>
      context.localizations.togetherModeTogether,
    FriendChallengeMode.competition =>
      context.localizations.togetherModeCompetition,
  };
}

/// Cómo va cada persona al entrenar juntos, en palabras.
extension WorkoutMemberStateLabel on WorkoutMemberState {
  String label(BuildContext context) => switch (this) {
    WorkoutMemberState.notStarted => context.localizations.togetherNotStarted,
    WorkoutMemberState.training => context.localizations.togetherTraining,
    WorkoutMemberState.finished => context.localizations.togetherFinished,
  };
}

/// Cifras de un reto con amigos con su unidad («5 de 12 días», «290 de 600
/// min»), con las mismas palabras que los retos que se cuentan solos.
extension FriendChallengeAmount on FriendChallenge {
  String amount(BuildContext context, int met, int target) => ChallengeRule(
    metric: metric,
    unit: unit,
    perUnit: 1,
    target: target,
    met: met,
  ).progressText(context);
}

/// Nombre de una persona; vacío si borró su cuenta.
String togetherName(BuildContext context, String name) =>
    name.isEmpty ? context.localizations.togetherDeletedUser : name;
