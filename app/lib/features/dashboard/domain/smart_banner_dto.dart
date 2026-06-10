/// Estado del ciclo de vida del SmartBanner.
enum SmartBannerStatus { loading, loaded, error, fallback }

/// Contexto que alimenta el prompt del SmartBanner con datos del usuario.
class SmartBannerContext {
  final double energiaValor;
  final double adherenciaValor;
  final double nivelEstres;
  final int evaluacionesSemana;
  final bool tieneExamenesProximos;
  final int? semanaActual;
  final int? totalSemanas;
  final int rachaEntrenamiento;
  final double rachaEstudio;

  const SmartBannerContext({
    required this.energiaValor,
    required this.adherenciaValor,
    required this.nivelEstres,
    required this.evaluacionesSemana,
    required this.tieneExamenesProximos,
    this.semanaActual,
    this.totalSemanas,
    required this.rachaEntrenamiento,
    required this.rachaEstudio,
  });

  /// Genera el prompt que se enviará a Gemini.
  String toPrompt() {
    final energiaLabel = energiaValor > 70
        ? 'alta'
        : energiaValor > 40
            ? 'media'
            : 'baja';
    final estresLabel = nivelEstres > 7
        ? 'alto'
        : nivelEstres > 4
            ? 'moderado'
            : 'bajo';
    final examenes = tieneExamenesProximos
        ? 'Sí hay exámenes próximos.'
        : 'No hay exámenes próximos.';
    final plan = semanaActual != null
        ? 'Está en la semana $semanaActual de $totalSemanas de su plan.'
        : '';

    return 'Eres un coach de bienestar académico-deportivo. '
        'Energía: $energiaLabel (${energiaValor.round()}/100). '
        'Estrés académico: $estresLabel. '
        '$examenes '
        '$plan '
        'Racha de entrenamiento: $rachaEntrenamiento días. '
        'Adherencia académica: ${adherenciaValor.round()}/100. '
        'Genera UN consejo motivacional breve de máximo 2 frases en español. '
        'Sé positivo, concreto y accionable. NO uses emojis. NO des recomendaciones médicas.';
  }
}

/// Estado del SmartBanner — mensaje generado o fallback.
class SmartBannerState {
  final SmartBannerStatus status;
  final String? mensaje;
  final String? fallbackMensaje;
  final DateTime? generadoEn;

  const SmartBannerState({
    this.status = SmartBannerStatus.loading,
    this.mensaje,
    this.fallbackMensaje,
    this.generadoEn,
  });

  bool get isExpired =>
      generadoEn != null && DateTime.now().difference(generadoEn!).inHours >= 1;

  String get textoVisible => mensaje ?? fallbackMensaje ?? 'Cargando...';
}
