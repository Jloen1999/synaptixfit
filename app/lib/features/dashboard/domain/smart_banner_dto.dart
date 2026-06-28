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

  /// Indica si el usuario ya completó el check-in diario. Si es `false`,
  /// el valor de energía no es fiable y no debe interpretarse como "baja".
  final bool tieneCheckIn;

  /// Indica si hay datos de carga académica. Si es `false`, la adherencia
  /// no es fiable y no debe interpretarse como "baja".
  final bool tieneAdherencia;

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
    required this.tieneCheckIn,
    required this.tieneAdherencia,
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
        ? 'Sí hay exámenes o entregas próximos.'
        : 'No hay exámenes ni entregas próximos.';
    final plan = semanaActual != null
        ? 'Está en la semana $semanaActual de $totalSemanas de su plan.'
        : '';

    final energiaInfo = tieneCheckIn
        ? 'Energía física: $energiaLabel (${energiaValor.round()}/100).'
        : 'El usuario AÚN NO ha registrado su check-in diario, por lo que NO '
            'conocemos su energía de hoy. NO asumas que está cansado ni bajo de '
            'energía; invítale de forma amable a hacer el check-in.';

    final adherenciaInfo = tieneAdherencia
        ? 'Adherencia académica: ${adherenciaValor.round()}/100 '
            '(racha de estudio: ${rachaEstudio.round()} días).'
        : 'Todavía no hay datos de carga académica; NO asumas que su adherencia '
            'es baja.';

    return 'Eres un coach de bienestar que equilibra el rendimiento ACADÉMICO y '
        'el DEPORTIVO. '
        '$energiaInfo '
        '$adherenciaInfo '
        'Estrés académico: $estresLabel. '
        '$examenes '
        '$plan '
        'Racha de entrenamiento: $rachaEntrenamiento días. '
        'Genera UN consejo motivacional breve de máximo 2 frases en español que '
        'integre lo académico y lo deportivo según el dato más relevante. '
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
