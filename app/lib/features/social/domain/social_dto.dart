/// DTO que representa una publicación en el muro social.
class Publicacion {
  final String id;
  final String usuarioId;
  final String nombreUsuario;
  final String? avatarUrl;
  final String descripcion;
  final String
      tipo; // 'session_completed', 'challenge_completed', 'milestone_reached', 'badge_unlocked'
  final String? urlImagen;
  final int likesCount;
  final int comentariosCount;
  final bool likedByMe;
  final DateTime fecha;
  final String? metadata;
  final DateTime? editadoEn;

  const Publicacion({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    this.avatarUrl,
    required this.descripcion,
    required this.tipo,
    this.urlImagen,
    required this.likesCount,
    required this.comentariosCount,
    required this.likedByMe,
    required this.fecha,
    this.metadata,
    this.editadoEn,
  });

  /// Indica si la publicación ha sido editada por su autor.
  bool get fueEditada => editadoEn != null;

  /// Construye una [Publicacion] desde un mapa de Supabase.
  ///
  /// [currentUserId] se usa para determinar [likedByMe] comparando con el
  /// usuario autenticado actual.
  factory Publicacion.fromMap(Map<String, dynamic> map, String currentUserId) {
    // Datos del usuario (vía join de Supabase)
    final usuarioData = map['usuarios'] as Map<String, dynamic>?;
    final nombreUsuario =
        usuarioData?['nombre_completo'] as String? ?? 'Usuario';
    final avatarUrl = usuarioData?['url_avatar'] as String?;

    // Conteo de likes (vía subconsulta agregada)
    final likesData = map['likes_count'] as List<dynamic>?;
    final likesCount = (likesData != null && likesData.isNotEmpty)
        ? ((likesData.first as Map<String, dynamic>)['count'] as int? ?? 0)
        : 0;

    // Conteo de comentarios
    final comentariosData = map['comentarios_count'] as List<dynamic>?;
    final comentariosCount = (comentariosData != null &&
            comentariosData.isNotEmpty)
        ? ((comentariosData.first as Map<String, dynamic>)['count'] as int? ??
            0)
        : 0;

    // ¿Le dio like el usuario actual?
    final miLikeData = map['mi_like'] as List<dynamic>?;
    final likedByMe = miLikeData != null && miLikeData.isNotEmpty;

    return Publicacion(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      nombreUsuario: nombreUsuario,
      avatarUrl: avatarUrl,
      descripcion: map['descripcion'] as String,
      tipo: map['tipo'] as String,
      urlImagen: map['url_imagen'] as String?,
      likesCount: likesCount,
      comentariosCount: comentariosCount,
      likedByMe: likedByMe,
      fecha: DateTime.parse(map['creado_en'] as String),
      metadata: map['metadata'] as String?,
      editadoEn: map['editado_en'] != null
          ? DateTime.parse(map['editado_en'] as String)
          : null,
    );
  }
}

/// DTO que representa un comentario en una publicación.
class Comentario {
  final String id;
  final String actividadId;
  final String usuarioId;
  final String nombreUsuario;
  final String? avatarUrl;
  final String texto;
  final DateTime fecha;
  final bool esMio;

  const Comentario({
    required this.id,
    required this.actividadId,
    required this.usuarioId,
    required this.nombreUsuario,
    this.avatarUrl,
    required this.texto,
    required this.fecha,
    required this.esMio,
  });

  /// Construye un [Comentario] desde un mapa de Supabase.
  ///
  /// [currentUserId] se usa para determinar [esMio].
  factory Comentario.fromMap(Map<String, dynamic> map, String currentUserId) {
    final usuarioData = map['usuarios'] as Map<String, dynamic>?;
    final nombreUsuario =
        usuarioData?['nombre_completo'] as String? ?? 'Usuario';
    final avatarUrl = usuarioData?['url_avatar'] as String?;

    return Comentario(
      id: map['id'] as String,
      actividadId: map['actividad_id'] as String,
      usuarioId: map['usuario_id'] as String,
      nombreUsuario: nombreUsuario,
      avatarUrl: avatarUrl,
      texto: map['texto'] as String,
      fecha: DateTime.parse(map['creado_en'] as String),
      esMio: map['usuario_id'] as String == currentUserId,
    );
  }
}
