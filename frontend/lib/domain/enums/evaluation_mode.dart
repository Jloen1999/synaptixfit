/// Modalidad de evaluación de una guía docente: continua o global (examen
/// final). La nota estimada solo cuenta los criterios de la modalidad activa.
enum EvaluationMode {
  continuous('CONTINUOUS'),
  global('GLOBAL');

  const EvaluationMode(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  static EvaluationMode? fromApi(String? value) {
    for (final v in EvaluationMode.values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}
