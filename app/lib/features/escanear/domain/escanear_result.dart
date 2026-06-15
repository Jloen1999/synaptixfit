/// Modo de escaneo soportado.
enum EscanearModo { texto }

/// Resultado de una operacion de escaneo OCR.
class EscanearResult {
  /// Texto extraido exitosamente.
  final String? texto;

  /// Mensaje de error si la operacion fallo.
  final String? error;

  /// Modo utilizado para el escaneo.
  final EscanearModo modo;

  /// ID de la asignatura asociada (opcional).
  final String? asignaturaId;

  const EscanearResult({
    this.texto,
    this.error,
    this.modo = EscanearModo.texto,
    this.asignaturaId,
  });

  bool get isSuccess => texto != null && texto!.isNotEmpty;
}
