import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_contenido_dto.dart';

/// Repositorio para la gestión de contenido reportado.
///
/// Permite listar, aprobar y eliminar contenido marcado como reportado
/// por usuarios, abarcando tanto publicaciones ([actividades_sociales])
/// como comentarios ([comentarios_feed]).
class AdminContenidoRepository {
  final SupabaseClient _client;

  const AdminContenidoRepository(this._client);

  /// Lista el contenido reportado de forma paginada, combinando publicaciones
  /// y comentarios en una sola lista ordenada por fecha descendente.
  Future<List<ContenidoReportado>> listarContenidoReportado({
    int page = 0,
    int limit = 20,
  }) async {
    final mitad = limit ~/ 2;

    // Consulta de actividades reportadas
    final actividadesData = await _client
        .from('actividades_sociales')
        .select(
          'id, usuario_id, descripcion, creado_en, '
          'usuarios!actividades_sociales_usuario_id_fkey(nombre_completo)',
        )
        .eq('reportado', true)
        .order('creado_en', ascending: false)
        .range(page * mitad, (page + 1) * mitad - 1)
        .timeout(const Duration(seconds: 10));

    // Consulta de comentarios reportados (no eliminados)
    final comentariosData = await _client
        .from('comentarios_feed')
        .select(
          'id, usuario_id, texto, creado_en, '
          'usuarios!comentarios_feed_usuario_id_fkey(nombre_completo)',
        )
        .eq('reportado', true)
        .eq('eliminado', false)
        .order('creado_en', ascending: false)
        .range(page * mitad, (page + 1) * mitad - 1)
        .timeout(const Duration(seconds: 10));

    final results = <ContenidoReportado>[];

    for (final map in actividadesData) {
      final usuario = map['usuarios'] as Map<String, dynamic>?;
      results.add(ContenidoReportado(
        id: map['id'] as String,
        tipo: ContenidoTipo.actividad,
        contenido: map['descripcion'] as String? ?? '',
        autorId: map['usuario_id'] as String,
        autorNombre: usuario?['nombre_completo'] as String?,
        creadoEn: DateTime.parse(map['creado_en'] as String),
      ));
    }

    for (final map in comentariosData) {
      final usuario = map['usuarios'] as Map<String, dynamic>?;
      results.add(ContenidoReportado(
        id: map['id'] as String,
        tipo: ContenidoTipo.comentario,
        contenido: map['texto'] as String? ?? '',
        autorId: map['usuario_id'] as String,
        autorNombre: usuario?['nombre_completo'] as String?,
        creadoEn: DateTime.parse(map['creado_en'] as String),
      ));
    }

    results.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return results;
  }

  /// Aprueba el contenido reportado, quitando la bandera de reportado.
  Future<void> aprobarContenido(ContenidoTipo tipo, String id) async {
    if (tipo == ContenidoTipo.actividad) {
      await _client
          .from('actividades_sociales')
          .update({'reportado': false})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } else {
      await _client
          .from('comentarios_feed')
          .update({'reportado': false})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    }
  }

  /// Elimina el contenido reportado.
  ///
  /// Para comentarios se aplica soft delete ([eliminado] = true).
  /// Para publicaciones se quita la bandera de reportado.
  Future<void> eliminarContenido(ContenidoTipo tipo, String id) async {
    if (tipo == ContenidoTipo.actividad) {
      await _client
          .from('actividades_sociales')
          .update({'reportado': false})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } else {
      await _client
          .from('comentarios_feed')
          .update({'eliminado': true, 'reportado': false})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    }
  }
}
