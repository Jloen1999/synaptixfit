import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/errors/app_error.dart';
import '../../../domain/models/account/account.dart';
import '../../../domain/models/training/recommendation.dart';
import '../../../domain/models/training/session.dart';

part 'training_effect.freezed.dart';

/// Efecto puntual que un bloc del módulo pide a su página (aviso, navegación,
/// refresco de la cuenta). Los blocs lo emiten y lo limpian en el estado siguiente.
@freezed
sealed class TrainingEffect with _$TrainingEffect {
  /// Error de una acción (la pantalla sigue mostrando sus datos).
  const factory TrainingEffect.error(AppError error) = TrainingEffectError;

  /// Aviso de éxito.
  const factory TrainingEffect.message(TrainingMessage message) =
      TrainingEffectMessage;

  /// Abrir una rutina (recién creada, duplicada o clonada).
  const factory TrainingEffect.openRoutine(
    String routineId, {
    @Default(false) bool replace,
  }) = TrainingEffectOpenRoutine;

  /// Abrir una sesión en vivo.
  const factory TrainingEffect.openSession(String sessionId) =
      TrainingEffectOpenSession;

  /// Sesión finalizada: abrir el resumen.
  const factory TrainingEffect.sessionFinished(FinishSessionResult result) =
      TrainingEffectSessionFinished;

  /// Día de rutina saltado: el aviso lleva «Deshacer» (saltar no se confirma).
  const factory TrainingEffect.daySkipped({
    required String routineId,
    required String dayId,
  }) = TrainingEffectDaySkipped;

  /// Sugerencia aplicada: el aviso lleva «Ver» a la rutina que cambió.
  const factory TrainingEffect.recommendationApplied({String? routineId}) =
      TrainingEffectRecommendationApplied;

  /// Sugerencia quitada de la lista: el aviso lleva «Deshacer» y, si se
  /// cierra sin deshacer, se descarta en el servidor (vocabulario §4).
  const factory TrainingEffect.recommendationDiscarded(
    Recommendation recommendation,
  ) = TrainingEffectRecommendationDiscarded;

  /// Cerrar la pantalla (p. ej. tras borrar o abandonar).
  const factory TrainingEffect.close() = TrainingEffectClose;

  /// La cuenta ha cambiado (experiencia, nivel).
  const factory TrainingEffect.accountChanged(Account account) =
      TrainingEffectAccountChanged;
}

/// Avisos de éxito del módulo.
enum TrainingMessage {
  routineSaved,
  routineDeleted,
  routineUpdated,
  routineDuplicated,
  routineCloned,
  planSaved,
  planDeleted,
  sessionAbandoned,
  setSaved,
  sessionShared,
  pendingSetDiscarded,
  daySkipped,
  dayUnskipped,
  sessionSavedOnItsDay,
  sessionDiscarded,
  sessionCorrected,
  sessionDeleted,
  routineStarted,
  routineRestarted,
  exerciseReplaced,
  exerciseRemoved,
}
