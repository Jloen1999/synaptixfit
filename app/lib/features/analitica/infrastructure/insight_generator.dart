import '../domain/insight_correlacion_dto.dart';

// ---------------------------------------------------------------------------
// Generador de frases interpretativas en espanol para insights de analitica.
// Todos los metodos son estaticos y no dependen de estado externo.
// ---------------------------------------------------------------------------

class InsightGenerator {
  InsightGenerator._();

  /// Genera una frase explicativa basada en un InsightCorrelacion.
  static String generarFraseCorrelacion(InsightCorrelacion c) {
    final abs = c.coeficiente.abs();
    final signo = c.coeficiente >= 0 ? '+' : '-';
    final porcentaje = (abs * 100).toStringAsFixed(0);

    if (abs < 0.2) {
      return 'Hasta ahora, tu estudio y tu rendimiento fisico no muestran '
          'una relacion clara. Cada area funciona a su propio ritmo.';
    }

    if (c.coeficiente >= 0.5) {
      return 'Cuando tu carga academica aumenta, tu rendimiento fisico '
          'tambien tiende a subir (correlacion $signo$porcentaje%). '
          'El ejercicio es tu aliado frente al estres academico.';
    }

    if (c.coeficiente <= -0.5) {
      return 'En semanas de mucho estudio, tu RPE baja un $porcentaje% '
          'en promedio. Es normal: el cansancio mental afecta al cuerpo. '
          'Ajusta la intensidad sin culpa.';
    }

    if (c.coeficiente >= 0.2) {
      return 'Hay una ligera tendencia positiva ($signo$porcentaje%): '
          'estudiar mas no te frena en el gym. Sigue asi.';
    }

    return 'Se nota una leve baja de rendimiento ($signo$porcentaje%) en '
        'semanas con mas estudio. Escucha a tu cuerpo y prioriza '
        'la recuperacion cuando sea necesario.';
  }

  /// Genera una frase motivacional sobre la racha de entrenamiento.
  static String generarFraseRacha(int dias) {
    if (dias <= 0) {
      return 'Hoy es un buen dia para empezar tu racha. Un solo '
          'entrenamiento marca la diferencia.';
    }

    if (dias == 1) {
      return 'Llevas 1 dia seguido entrenando. El primer paso es '
          'el mas importante. Sigue asi manana.';
    }

    if (dias < 7) {
      return 'Llevas $dias dias seguidos entrenando. '
          'Estas construyendo un habito solido. Cada dia cuenta.';
    }

    if (dias < 30) {
      final semanas = (dias / 7).floor();
      return 'Llevas $dias dias seguidos (aproximadamente $semanas semanas). '
          'Tu consistencia esta dando frutos. Sigue rompiendo tus limites.';
    }

    if (dias < 90) {
      return 'Llevas $dias dias sin parar. Has convertido el entrenamiento '
          'en un habito de acero. Eres un ejemplo de disciplina.';
    }

    return 'Llevas $dias dias seguidos entrenando. '
        'Eres practicamente imparable. Tu dedicacion es inspiradora.';
  }

  /// Genera una frase sobre la consistencia semanal de entrenamiento.
  static String generarFraseConsistencia(int semanasConsecutivas) {
    if (semanasConsecutivas <= 0) {
      return 'Esta semana puedes empezar una nueva racha de consistencia.';
    }

    if (semanasConsecutivas == 1) {
      return 'Completaste tu primera semana de entrenamiento. '
          'Una semana mas y sera un habito.';
    }

    if (semanasConsecutivas < 4) {
      return '$semanasConsecutivas semanas consecutivas entrenando. '
          'La constancia vence todo.';
    }

    return '$semanasConsecutivas semanas seguidas sin fallar. '
        'Tu adherencia es de nivel elite. Asi es como se construye '
        'un cambio real.';
  }

  /// Genera una frase sobre el volumen total de entrenamiento.
  static String generarFraseVolumen(int minutosTotales, int semanas) {
    final horas = minutosTotales / 60;
    final prom = horas / semanas;

    if (horas < 1) {
      return 'Tu volumen de entrenamiento aun es bajo. Cada minuto '
          'cuenta, sigue sumando.';
    }

    return 'En las ultimas semanas acumulaste ${horas.toStringAsFixed(0)}h '
        'de entrenamiento (${prom.toStringAsFixed(1)}h/semana). '
        'Ese tiempo invertido es oro para tu salud.';
  }
}
