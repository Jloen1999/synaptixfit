/// Tipos de contenido que pueden ser reportados en la plataforma.
enum ContenidoTipo { actividad, comentario }

/// DTO que representa contenido reportado pendiente de moderación.
///
/// Agrupa tanto publicaciones ([actividades_sociales]) como comentarios
/// ([comentarios_feed]) que han sido marcados como reportados por usuarios.
class ContenidoReportado {
  const ContenidoReportado({
    required this.id,
    required this.tipo,
    required this.contenido,
    required this.autorId,
    required this.creadoEn,
    this.autorNombre,
  });

  final String id;
  final ContenidoTipo tipo;
  final String contenido;
  final String autorId;
  final String? autorNombre;
  final DateTime creadoEn;

  /// Construye una instancia desde un mapa, especificando el [tipo] de contenido.
  factory ContenidoReportado.fromMap(
    Map<String, dynamic> map, {
    required ContenidoTipo tipo,
  }) {
    return ContenidoReportado(
      id: map['id'] as String,
      tipo: tipo,
      contenido: (map['contenido'] as String?) ?? map['texto'] as String? ?? '',
      autorId: map['usuario_id'] as String,
      autorNombre: map['autor_nombre'] as String?,
      creadoEn: DateTime.parse(map['creado_en'] as String),
    );
  }
}
