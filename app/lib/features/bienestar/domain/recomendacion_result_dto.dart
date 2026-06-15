import 'ejercicio_recomendado_dto.dart';

/// Resultado de la generación de metadatos y estructura de una rutina completa.
class RecomendacionRutinaResult {
  const RecomendacionRutinaResult({
    required this.nombre,
    required this.descripcion,
    required this.objetivo,
    required this.duracionSemanas,
    required this.estructura,
    this.error,
  });

  final String nombre;
  final String descripcion;
  final String objetivo;
  final int duracionSemanas;
  final Map<int, Map<int, List<EjercicioRecomendado>>> estructura;
  final String? error;

  bool get tieneError => error != null;
}

/// Resultado de la generación de ejercicios para un día específico.
class RecomendacionEjerciciosResult {
  const RecomendacionEjerciciosResult({
    required this.ejercicios,
    this.error,
  });

  final List<EjercicioRecomendado> ejercicios;
  final String? error;

  bool get tieneError => error != null;
}
