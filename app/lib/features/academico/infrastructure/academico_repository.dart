import '../domain/asignatura_dto.dart';
import '../domain/plan_estudio_dto.dart';

/// Repositorio de datos académicos (esqueleto).
///
/// Los métodos stub lanzan [UnimplementedError] — la implementación real
/// de queries a Supabase se hará en un sprint futuro.
class AcademicoRepository {
  const AcademicoRepository();

  /// Obtiene los planes de estudio del usuario autenticado.
  Future<List<PlanEstudioDto>> obtenerPlanesEstudio() {
    throw UnimplementedError('obtenerPlanesEstudio() — sprint pendiente');
  }

  /// Obtiene las asignaturas de un plan de estudio.
  Future<List<AsignaturaDto>> obtenerAsignaturas(String planEstudioId) {
    throw UnimplementedError('obtenerAsignaturas() — sprint pendiente');
  }
}
