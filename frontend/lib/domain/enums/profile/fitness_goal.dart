/// Objetivo principal de entrenamiento del perfil físico.
enum FitnessGoal {
  hypertrophy('HYPERTROPHY'),
  maxStrength('MAX_STRENGTH'),
  power('POWER'),
  strengthEndurance('STRENGTH_ENDURANCE'),
  mobility('MOBILITY'),
  stability('STABILITY'),
  metabolicConditioning('METABOLIC_CONDITIONING');

  const FitnessGoal(this.apiValue);

  final String apiValue;

  static FitnessGoal? fromApi(String? value) {
    for (final v in values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}
