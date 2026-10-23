/// Recuerda, mientras la app está abierta, para qué usuarios ya se comprobó el
/// onboarding desde el inicio, para redirigir como mucho una vez por sesión.
class HomeOnboardingGate {
  final _checked = <String>{};

  /// Devuelve `true` la primera vez que se pregunta por [userId].
  bool shouldCheck(String userId) => _checked.add(userId);
}
