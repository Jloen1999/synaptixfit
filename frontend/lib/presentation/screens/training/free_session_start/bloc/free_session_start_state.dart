part of 'free_session_start_bloc.dart';

@freezed
abstract class FreeSessionStartState with _$FreeSessionStartState {
  const factory FreeSessionStartState({
    /// Ejercicios elegidos, en orden.
    @Default(<Exercise>[]) List<Exercise> chosen,

    /// Últimos entrenos para repetir (vacío si no hay o si falla la lectura).
    @Default(<SessionHistoryEntry>[]) List<SessionHistoryEntry> recent,
    @Default(false) bool recentLoaded,
    @Default(false) bool starting,

    /// Plantillas (nulas hasta pedirlas) y la abierta con sus días.
    List<RoutineTemplate>? templates,
    String? openTemplateId,
    RoutineTemplateDetail? templateDetail,
    AppError? templatesError,
    TrainingEffect? effect,
  }) = _FreeSessionStartState;
}
