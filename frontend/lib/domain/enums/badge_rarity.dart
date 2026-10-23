/// Rareza de una insignia, de más común a más difícil.
enum BadgeRarity {
  common,
  rare,
  epic,
  legendary;

  static BadgeRarity fromApi(String? value) => switch (value) {
    'RARE' => rare,
    'EPIC' => epic,
    'LEGENDARY' => legendary,
    _ => common,
  };
}
