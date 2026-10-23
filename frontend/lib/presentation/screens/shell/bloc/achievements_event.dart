part of 'achievements_bloc.dart';

@freezed
sealed class AchievementsEvent with _$AchievementsEvent {
  /// Entrada en la app con la cuenta de la sesión (nivel de partida).
  const factory AchievementsEvent.started({Account? account}) =
      AchievementsStarted;

  /// Alguna acción ha podido cambiar XP, nivel o insignias.
  const factory AchievementsEvent.dataChanged() = AchievementsDataChanged;

  /// Se ha cerrado la celebración de [level] y [badgeIds].
  const factory AchievementsEvent.celebrated({
    int? level,
    @Default(<String>[]) List<String> badgeIds,
  }) = AchievementsCelebrated;
}
