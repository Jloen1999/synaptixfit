/// Resumen semanal por correo: apagado, pendiente de confirmar desde el correo
/// o activo (ADR 0022).
enum WeeklyEmailStatus {
  off,
  pending,
  active;

  static WeeklyEmailStatus fromApi(String? value) => switch (value) {
    'ACTIVE' => active,
    'PENDING' => pending,
    _ => off,
  };
}
