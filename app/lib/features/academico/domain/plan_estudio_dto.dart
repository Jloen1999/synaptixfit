/// DTO que representa un plan de estudio (carrera) del usuario.
class PlanEstudioDto {
  final String id;
  final String nombre;
  final String carreraId;
  final int asignaturasCount;
  final double progresoPorcentaje;

  const PlanEstudioDto({
    required this.id,
    required this.nombre,
    required this.carreraId,
    required this.asignaturasCount,
    required this.progresoPorcentaje,
  });
}
