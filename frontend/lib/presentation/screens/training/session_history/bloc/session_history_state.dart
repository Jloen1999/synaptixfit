part of 'session_history_bloc.dart';

enum HistoryStatus { loading, ready, failure }

@freezed
abstract class SessionHistoryState with _$SessionHistoryState {
  const factory SessionHistoryState({
    @Default(HistoryStatus.loading) HistoryStatus status,
    @Default(<SessionHistoryEntry>[]) List<SessionHistoryEntry> items,

    /// Sesiones sin terminar (en curso y abandonadas), arriba del historial.
    @Default(<OpenSession>[]) List<OpenSession> open,

    /// Mejor marca actual de cada ejercicio (la más reciente primero).
    @Default(<PersonalRecord>[]) List<PersonalRecord> records,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,
    @Default(false) bool refreshing,
    @Default(<String>{}) Set<String> busyIds,
    AppError? error,
    TrainingEffect? effect,
  }) = _SessionHistoryState;
}
