/// Qué frase dice «Tu nota» sobre el aprobado; lo decide el servidor: sin notas
/// todavía, la media que falta en lo que queda, ya aprobado o ya no se llega.
enum PassOutlook {
  noGrades('NO_GRADES'),
  needsAverage('NEEDS_AVERAGE'),
  alreadyPassed('ALREADY_PASSED'),
  outOfReach('OUT_OF_REACH');

  const PassOutlook(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  /// Un valor desconocido (servidor más nuevo) se trata como «sin notas»: la
  /// pantalla no promete nada que no sepa.
  static PassOutlook fromApi(String? value) =>
      values.where((v) => v.apiValue == value).firstOrNull ?? noGrades;
}
