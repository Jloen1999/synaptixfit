import 'dart:math' as math;

/// Servicio de cálculo calórico para bloques de estudio.
///
/// Implementa la ecuación de Mifflin-St Jeor (1990) para la Tasa Metabólica
/// en Reposo (RMR) y la aplica junto con los coeficientes MET del Compendio
/// de Actividades Físicas para Adultos (3ª edición, 2024) para cuantificar
/// el gasto energético de las tareas cognitivas.
///
/// Fundamento:
///   RMR = 10·P + 6.25·H − 5·A + S
///     P = peso en kg, H = altura en cm, A = edad en años
///     S = +5 (masculino), −161 (femenino)
///
///   Gasto Bloque = (RMR / 86400) · duracionSegundos · MET
///
/// MET cognitivo: 1.3 para estudio/repaso/escritura, 1.8 para clase.
class StudyCalorieService {
  const StudyCalorieService._();

  static const _metEstudio = 1.3;
  static const _metClase = 1.8;

  static const _segundosPorDia = 86400;
  static const _sexoMasculino = 'masculino';

  /// Calcula la Tasa Metabólica en Reposo (kcal/día) según Mifflin-St Jeor.
  ///
  /// [pesoKg] — peso corporal en kilogramos.
  /// [alturaCm] — estatura en centímetros.
  /// [edad] — edad en años cumplidos.
  /// [sexo] — 'masculino' o 'femenino'.
  static double calcularRMR({
    required double pesoKg,
    required double alturaCm,
    required int edad,
    required String sexo,
  }) {
    final ajusteDimorfico =
        sexo.trim().toLowerCase() == _sexoMasculino ? 5.0 : -161.0;
    return 10.0 * pesoKg + 6.25 * alturaCm - 5.0 * edad + ajusteDimorfico;
  }

  /// Calcula el gasto calórico de un bloque de estudio.
  ///
  /// [rmr] — tasa metabólica en reposo en kcal/día.
  /// [duracionSegundos] — duración ininterrumpida del bloque.
  /// [metValue] — coeficiente MET cognitivo de la tarea.
  static double calcularGastoEstudio({
    required double rmr,
    required int duracionSegundos,
    required double metValue,
  }) {
    if (duracionSegundos <= 0) return 0;
    return (rmr / _segundosPorDia) * duracionSegundos * metValue;
  }

  /// Deriva el coeficiente MET cognitivo según el tipo de actividad académica.
  ///
  /// - 'clase' → 1.8 (asistencia + toma de apuntes + discusión).
  /// - 'estudio', 'repaso' → 1.3 (lectura/escritura pasiva).
  /// - Otros → 1.3 (default conservador, mismo que lectura).
  static double metCognitivoParaActividad(String tipoActividad) {
    final t = tipoActividad.trim().toLowerCase();
    if (t == 'clase') return _metClase;
    return _metEstudio;
  }

  /// Redondea calorías a entero para presentación en UI.
  static int redondear(double calorias) => calorias.round();

  /// Convierte duración en segundos a minutos (entero, mínimo 1).
  static int segundosAMinutos(int segundos) => math.max(1, segundos ~/ 60);
}
