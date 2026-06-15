/// DTO que representa una asignatura del plan de estudio.
class AsignaturaDto {
  final String id;
  final String nombre;
  final String profesor;
  final int creditos;
  final String horario;

  const AsignaturaDto({
    required this.id,
    required this.nombre,
    required this.profesor,
    required this.creditos,
    required this.horario,
  });
}
