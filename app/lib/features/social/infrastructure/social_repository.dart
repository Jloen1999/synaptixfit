import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/social_dto.dart';

/// Repositorio de datos sociales con queries reales a Supabase.
class SocialRepository {
  final SupabaseClient _client;

  const SocialRepository(this._client);

  /// Obtiene el feed de publicaciones recientes con datos de usuario,
  /// conteos de likes/comentarios y si el usuario actual dio like.
  ///
  /// Optimizado: usa 3 consultas en lote (actividades + likes + comentarios)
  /// en lugar de N+1 por publicación, de modo que el refresco en tiempo real
  /// sea barato independientemente del número de publicaciones.
  Future<List<Publicacion>> obtenerFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    final userId = _client.auth.currentUser?.id ?? '';

    final data = await _client
        .from('actividades_sociales')
        .select('*, usuarios:usuario_id(nombre_completo, url_avatar)')
        .order('creado_en', ascending: false)
        .range(offset, offset + limit - 1);

    final actividades = (data as List).cast<Map<String, dynamic>>();
    if (actividades.isEmpty) return [];

    final ids = actividades.map((a) => a['id'] as String).toList();

    // Lote 1: todos los likes de la página.
    final likesData = await _client
        .from('interacciones_sociales')
        .select('actividad_id, usuario_id')
        .inFilter('actividad_id', ids)
        .eq('tipo_interaccion', 'like');

    final likesPorActividad = <String, int>{};
    final misLikes = <String>{};
    for (final l in (likesData as List)) {
      final aid = l['actividad_id'] as String;
      likesPorActividad[aid] = (likesPorActividad[aid] ?? 0) + 1;
      if (userId.isNotEmpty && l['usuario_id'] == userId) {
        misLikes.add(aid);
      }
    }

    // Lote 2: conteo real de comentarios (comentarios_feed, no eliminados).
    final comentariosData = await _client
        .from('comentarios_feed')
        .select('actividad_id')
        .inFilter('actividad_id', ids)
        .eq('eliminado', false);

    final comentariosPorActividad = <String, int>{};
    for (final c in (comentariosData as List)) {
      final aid = c['actividad_id'] as String;
      comentariosPorActividad[aid] = (comentariosPorActividad[aid] ?? 0) + 1;
    }

    return actividades.map((map) {
      final actividadId = map['id'] as String;
      final usuarioData = map['usuarios'] as Map<String, dynamic>?;
      return Publicacion(
        id: actividadId,
        usuarioId: map['usuario_id'] as String,
        nombreUsuario: usuarioData?['nombre_completo'] as String? ?? 'Usuario',
        avatarUrl: usuarioData?['url_avatar'] as String?,
        descripcion: map['descripcion'] as String,
        tipo: map['tipo'] as String,
        urlImagen: map['url_imagen'] as String?,
        likesCount: likesPorActividad[actividadId] ?? 0,
        comentariosCount: comentariosPorActividad[actividadId] ?? 0,
        likedByMe: misLikes.contains(actividadId),
        fecha: DateTime.parse(map['creado_en'] as String),
        metadata: map['metadata'] as String?,
        editadoEn: map['editado_en'] != null
            ? DateTime.parse(map['editado_en'] as String)
            : null,
      );
    }).toList();
  }

  /// Da like a una actividad.
  ///
  /// Si ya existe la interacción, no hace nada (idempotente vía upsert).
  Future<void> darLike(String actividadId, String usuarioId) async {
    // Verificar si ya existe
    final existente = await _client
        .from('interacciones_sociales')
        .select('id')
        .eq('actividad_id', actividadId)
        .eq('usuario_id', usuarioId)
        .eq('tipo_interaccion', 'like')
        .maybeSingle();

    if (existente != null) return;

    await _client.from('interacciones_sociales').insert({
      'actividad_id': actividadId,
      'usuario_id': usuarioId,
      'tipo_interaccion': 'like',
    });
  }

  /// Quita el like de una actividad.
  Future<void> quitarLike(String actividadId, String usuarioId) async {
    await _client
        .from('interacciones_sociales')
        .delete()
        .eq('actividad_id', actividadId)
        .eq('usuario_id', usuarioId)
        .eq('tipo_interaccion', 'like');
  }

  /// Crea una publicación en el feed social.
  ///
  /// [metadata] es un JSON serializado (TEXT) opcional con la entidad
  /// vinculada (insignia, rutina o reto) seleccionada por el usuario.
  Future<String?> crearPublicacion({
    required String usuarioId,
    required String descripcion,
    String? urlImagen,
    String tipo = 'milestone_reached',
    String? metadata,
  }) async {
    final data = await _client
        .from('actividades_sociales')
        .insert({
          'usuario_id': usuarioId,
          'tipo': tipo,
          'descripcion': descripcion,
          'url_imagen': urlImagen,
          if (metadata != null) 'metadata': metadata,
        })
        .select('id')
        .maybeSingle();

    return data?['id'] as String?;
  }

  /// Edita la descripción de una publicación propia y marca `editado_en`
  /// para que la UI refleje que fue editada. La RLS garantiza que solo el
  /// autor puede actualizarla.
  Future<void> editarPublicacion(
      String publicacionId, String descripcion) async {
    await _client.from('actividades_sociales').update({
      'descripcion': descripcion,
      'editado_en': DateTime.now().toIso8601String(),
    }).eq('id', publicacionId);
  }

  /// Elimina una publicación propia. Los comentarios asociados se eliminan en
  /// cascada (FK ON DELETE CASCADE). La RLS garantiza que solo el autor puede
  /// eliminarla.
  Future<void> eliminarPublicacion(String publicacionId) async {
    await _client.from('actividades_sociales').delete().eq('id', publicacionId);
  }

  /// Obtiene los comentarios de una actividad, incluyendo datos del autor.
  Future<List<Comentario>> obtenerComentarios(String actividadId) async {
    final userId = _client.auth.currentUser?.id ?? '';

    final data = await _client
        .from('comentarios_feed')
        .select('*, usuarios:usuario_id(nombre_completo, url_avatar)')
        .eq('actividad_id', actividadId)
        .eq('eliminado', false)
        .order('creado_en', ascending: true);

    final lista = data as List;

    return lista
        .map((c) => Comentario.fromMap(c as Map<String, dynamic>, userId))
        .toList();
  }

  /// Añade un comentario a una actividad.
  Future<Comentario> agregarComentario({
    required String actividadId,
    required String usuarioId,
    required String texto,
  }) async {
    final userId = _client.auth.currentUser?.id ?? usuarioId;

    final data = await _client
        .from('comentarios_feed')
        .insert({
          'actividad_id': actividadId,
          'usuario_id': usuarioId,
          'texto': texto,
        })
        .select('*, usuarios:usuario_id(nombre_completo, url_avatar)')
        .single();

    // Notificar al autor de la actividad (si no es el mismo usuario)
    _notificarComentario(actividadId, usuarioId);

    return Comentario.fromMap(data, userId);
  }

  /// Notifica al autor de una actividad sobre un nuevo comentario.
  Future<void> _notificarComentario(
      String actividadId, String comentaristaId) async {
    try {
      final actividad = await _client
          .from('actividades_sociales')
          .select('usuario_id, descripcion')
          .eq('id', actividadId)
          .maybeSingle();

      if (actividad == null) return;

      final autorId = actividad['usuario_id'] as String;
      if (autorId == comentaristaId) return;

      await _client.from('notificaciones').insert({
        'usuario_id': autorId,
        'titulo': 'Nuevo comentario',
        'descripcion': 'Alguien comentó en tu publicación',
        'prioridad': 'informative',
        'tipo': 'social',
      });
    } catch (_) {
      // La notificación es best-effort; no falla el comentario si falla.
    }
  }

  /// Edita el texto de un comentario (solo el autor).
  Future<void> editarComentario(String comentarioId, String texto) async {
    await _client.from('comentarios_feed').update({
      'texto': texto,
      'editado_en': DateTime.now().toIso8601String(),
    }).eq('id', comentarioId);
  }

  /// Elimina un comentario (soft delete, solo el autor).
  Future<void> eliminarComentario(String comentarioId) async {
    await _client.from('comentarios_feed').update({
      'eliminado': true,
    }).eq('id', comentarioId);
  }

  /// Verifica si el usuario actual dio like a una actividad.
  Future<bool> tieneLike(String actividadId, String usuarioId) async {
    final data = await _client
        .from('interacciones_sociales')
        .select('id')
        .eq('actividad_id', actividadId)
        .eq('usuario_id', usuarioId)
        .eq('tipo_interaccion', 'like')
        .maybeSingle();

    return data != null;
  }
}
