import 'package:flutter/material.dart';

import '../../../../../domain/enums/together_enums.dart';
import '../../../../extensions/context_extensions.dart';

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

/// Nombre de una persona; vacío si borró su cuenta.
String togetherName(BuildContext context, String name) =>
    name.isEmpty ? context.localizations.togetherDeletedUser : name;
