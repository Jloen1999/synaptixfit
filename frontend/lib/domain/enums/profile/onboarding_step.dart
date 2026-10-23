/// Paso del onboarding.
enum OnboardingStep {
  account('ACCOUNT'),
  focus('FOCUS'),
  wellnessProfile('WELLNESS_PROFILE'),
  academicProfile('ACADEMIC_PROFILE'),
  subjects('SUBJECTS');

  const OnboardingStep(this.apiValue);

  final String apiValue;

  static OnboardingStep? fromApi(String? value) {
    for (final v in values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}
