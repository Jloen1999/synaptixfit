part of 'free_session_start_bloc.dart';

@freezed
sealed class FreeSessionStartEvent with _$FreeSessionStartEvent {
  /// Lee los últimos entrenos (para «Repetir un entreno»).
  const factory FreeSessionStartEvent.started() = FreeSessionStartStarted;

  /// Suma o quita un ejercicio de la lista elegida (en el orden en que se
  /// eligen).
  const factory FreeSessionStartEvent.exerciseToggled(Exercise exercise) =
      FreeSessionStartExerciseToggled;

  /// Empieza: con [source] nulo, con los ejercicios elegidos (puede ir vacía).
  const factory FreeSessionStartEvent.startRequested([
    FreeSessionSource? source,
  ]) = FreeSessionStartStartRequested;

  /// Pide las plantillas (una vez) para «Un día de una plantilla».
  const factory FreeSessionStartEvent.templatesRequested() =
      FreeSessionStartTemplatesRequested;

  /// Abre una plantilla para ver sus días; nulo vuelve a la lista.
  const factory FreeSessionStartEvent.templateOpened(String? templateId) =
      FreeSessionStartTemplateOpened;
}
