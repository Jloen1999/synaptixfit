import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// De dónde sale la lista de una sesión libre (ADR 0067): una sola fuente.
sealed class FreeSessionSource {
  const FreeSessionSource();
}

/// Ejercicios elegidos a mano (puede ir vacía: se suman dentro).
class ChosenExercises extends FreeSessionSource {
  const ChosenExercises(this.exerciseIds);
  final List<String> exerciseIds;
}

/// Repetir lo que se hizo en una sesión anterior.
class RepeatSession extends FreeSessionSource {
  const RepeatSession(this.sessionId);
  final String sessionId;
}

/// Un día de una plantilla de rutina, sin guardarla como rutina.
class TemplateDay extends FreeSessionSource {
  const TemplateDay(this.templateId, this.dayNumber);
  final String templateId;
  final int dayNumber;
}

/// Empieza una sesión libre con su lista de ejercicios; las cifras de partida
/// las pone el servidor.
abstract interface class StartFreeSessionUseCaseContract {
  Future<AppResult<TrainingSession>> call(FreeSessionSource source);
}

class StartFreeSessionUseCase implements StartFreeSessionUseCaseContract {
  const StartFreeSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingSession>> call(FreeSessionSource source) =>
      switch (source) {
        ChosenExercises(:final exerciseIds) => _repository.startFreeSession(
          exerciseIds: exerciseIds,
        ),
        RepeatSession(:final sessionId) => _repository.startFreeSession(
          fromSessionId: sessionId,
        ),
        TemplateDay(:final templateId, :final dayNumber) =>
          _repository.startFreeSession(
            templateId: templateId,
            templateDayNumber: dayNumber,
          ),
      };
}
