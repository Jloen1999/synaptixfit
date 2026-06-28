/// DTO que representa un ejercicio en el catálogo desde el panel de administración.
///
/// Incluye el estado [activo] que permite a los administradores deshabilitar
/// ejercicios sin eliminarlos de la base de datos.
class AdminEjercicio {
  const AdminEjercicio({
    required this.id,
    required this.nombre,
    required this.activo,
    this.dificultad,
    this.finalidad,
    this.modalidadEntrenamiento,
  });

  final String id;
  final String nombre;
  final bool activo;
  final String? dificultad;
  final List<String>? finalidad;
  final String? modalidadEntrenamiento;

  /// Construye una instancia desde un mapa proveniente de Supabase.
  factory AdminEjercicio.fromMap(Map<String, dynamic> map) {
    return AdminEjercicio(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      activo: (map['activo'] as bool?) ?? true,
      dificultad: map['dificultad'] as String?,
      finalidad: (map['finalidad'] as List?)?.cast<String>(),
      modalidadEntrenamiento: map['modalidad_entrenamiento'] as String?,
    );
  }
}
