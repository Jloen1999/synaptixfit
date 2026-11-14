import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../mixins/errors_message_mixin.dart';
import '../../../theme/tokens.g.dart';
import '../../auth/session/bloc/session_bloc.dart';
import '../training_effect.dart';
import '../training_routes.dart';

/// Ejecuta en la página el efecto puntual que pide un bloc del módulo.
class TrainingEffectHandler with ErrorsMessageMixin {
  const TrainingEffectHandler();

  /// [onUnskipDay]: «Deshacer» del aviso de día saltado (saltar no se
  /// confirma: es reversible). Sin él, el aviso dice dónde recuperarlo.
  void handle(
    BuildContext context,
    TrainingEffect effect, {
    void Function(String routineId, String dayId)? onUnskipDay,
  }) {
    final l10n = context.localizations;
    switch (effect) {
      case TrainingEffectError(:final error):
        context.showSnack(errorMessage(context, error));
      // Publicar dice dónde queda y lleva allí (vocabulario.md).
      case TrainingEffectMessage(message: TrainingMessage.sessionShared):
        context.showActionSnack(
          l10n.trainingMsgSessionShared,
          actionLabel: l10n.commonView,
          onAction: () => context.push(TrainingPaths.communityWall),
        );
      case TrainingEffectMessage(:final message):
        context.showSnack(messageText(context.localizations, message));
      case TrainingEffectOpenRoutine(:final routineId, :final replace):
        if (replace && context.canPop()) {
          context.pushReplacement(TrainingPaths.routine(routineId));
        } else {
          context.push(TrainingPaths.routine(routineId));
        }
      case TrainingEffectOpenSession(:final sessionId):
        context.push(TrainingPaths.session(sessionId));
      case TrainingEffectSessionFinished(:final result):
        context.pushReplacement(
          TrainingPaths.sessionCompleted(result.session.id),
          extra: result,
        );
      case TrainingEffectDaySkipped(:final routineId, :final dayId):
        // Reversible: aviso con «Deshacer» durante la ventana de deshacer.
        if (onUnskipDay != null) {
          context.showActionSnack(
            l10n.trainingDaySkippedHere,
            actionLabel: l10n.commonUndo,
            onAction: () => onUnskipDay(routineId, dayId),
            duration: TokensDuration.undoWindow,
          );
        } else {
          context.showSnack(l10n.trainingDaySkipped);
        }
      case TrainingEffectClose():
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(TrainingPaths.root);
        }
      case TrainingEffectAccountChanged(:final account):
        context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
    }
  }

  static String messageText(
    AppLocalizations l10n,
    TrainingMessage m,
  ) => switch (m) {
    TrainingMessage.recommendationApplied =>
      l10n.trainingMsgRecommendationApplied,
    TrainingMessage.recommendationDiscarded =>
      l10n.trainingMsgRecommendationDiscarded,
    TrainingMessage.routineSaved => l10n.trainingMsgRoutineSaved,
    TrainingMessage.routineDeleted => l10n.trainingMsgRoutineDeleted,
    TrainingMessage.routineUpdated => l10n.commonSaved,
    TrainingMessage.routineDuplicated => l10n.trainingMsgRoutineDuplicated,
    TrainingMessage.routineCloned => l10n.trainingMsgRoutineCloned,
    TrainingMessage.checkInSaved => l10n.trainingMsgCheckInSaved,
    TrainingMessage.planSaved => l10n.trainingMsgPlanSaved,
    TrainingMessage.planDeleted => l10n.trainingMsgPlanDeleted,
    TrainingMessage.sessionAbandoned => l10n.trainingMsgSessionAbandoned,
    TrainingMessage.setSaved => l10n.trainingMsgSetSaved,
    TrainingMessage.sessionShared => l10n.trainingMsgSessionShared,
    TrainingMessage.daySkipped => l10n.trainingDaySkipped,
    TrainingMessage.dayUnskipped => l10n.trainingDayUnskipped,
    TrainingMessage.sessionSavedOnItsDay => l10n.trainingSessionSavedOnItsDay,
    TrainingMessage.sessionDiscarded => l10n.trainingSessionDiscarded,
    TrainingMessage.sessionCorrected => l10n.trainingSessionCorrected,
    TrainingMessage.sessionDeleted => l10n.trainingSessionDeleted,
    TrainingMessage.routineStarted => l10n.trainingRoutineStarted,
    TrainingMessage.routineRestarted => l10n.trainingRoutineRestarted,
    TrainingMessage.exerciseReplaced => l10n.trainingMsgExerciseReplaced,
    TrainingMessage.exerciseRemoved => l10n.trainingMsgExerciseRemoved,
    TrainingMessage.pendingSetDiscarded => l10n.trainingMsgPendingSetDiscarded,
  };
}
