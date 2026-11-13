/// Nivel en palabras de la carga cognitiva o de la atención («Tu equilibrio»).
/// Los umbrales los decide el servidor (ADR 0039); el cliente solo elige el
/// texto y el color. [unknown]: un servidor antiguo que aún no lo manda.
enum CognitiveLevel {
  low,
  moderate,
  high,
  critical,
  unknown;

  static CognitiveLevel fromApi(String? value) => switch (value) {
    'LOW' => low,
    'MODERATE' => moderate,
    'HIGH' => high,
    'CRITICAL' => critical,
    _ => unknown,
  };
}
