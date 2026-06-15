// ---------------------------------------------------------------------------
// Enum para el periodo de agregacion de las metricas de analitica.
// ---------------------------------------------------------------------------

/// Define la ventana temporal para la que se muestran las metricas.
enum PeriodoAnalitica {
  /// Ultimas 4 semanas (1 mes).
  cuatroSemanas,

  /// Ultimas 12 semanas (3 meses).
  doceSemanas,

  /// Ultimas 52 semanas (1 ano).
  cincuentaDosSemanas;

  /// Cantidad de semanas que abarca cada periodo.
  int get semanas {
    switch (this) {
      case PeriodoAnalitica.cuatroSemanas:
        return 4;
      case PeriodoAnalitica.doceSemanas:
        return 12;
      case PeriodoAnalitica.cincuentaDosSemanas:
        return 52;
    }
  }

  /// Etiqueta legible para la UI.
  String get etiqueta {
    switch (this) {
      case PeriodoAnalitica.cuatroSemanas:
        return '4 semanas';
      case PeriodoAnalitica.doceSemanas:
        return '12 semanas';
      case PeriodoAnalitica.cincuentaDosSemanas:
        return '52 semanas';
    }
  }
}
