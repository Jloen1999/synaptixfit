part of 'achievements_bloc.dart';

@freezed
abstract class AchievementsState with _$AchievementsState {
  const factory AchievementsState({
    /// Último nivel conocido, para detectar subidas.
    int? knownLevel,

    /// Cuenta recién recargada (la página la pasa a la sesión global).
    Account? account,

    /// Nivel alcanzado pendiente de celebrar.
    int? levelReached,

    /// Insignias pendientes de celebrar.
    @Default(<Badge>[]) List<Badge> badges,
  }) = _AchievementsState;

  const AchievementsState._();

  bool get hasCelebration => levelReached != null || badges.isNotEmpty;
}
