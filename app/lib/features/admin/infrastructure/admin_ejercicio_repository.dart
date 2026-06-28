import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_ejercicio_dto.dart';

/// Repositorio para la gestión del catálogo de ejercicios desde el panel de
/// administración.
///
/// Permite listar ejercicios con búsqueda y paginación, y activar/desactivar
/// ejercicios individuales sin eliminarlos de la base de datos.
class AdminEjercicioRepository {
  final SupabaseClient _client;

  const AdminEjercicioRepository(this._client);

  /// Lista ejercicios del catálogo con búsqueda opcional por nombre.
  ///
  /// [query] permite filtrar por coincidencia parcial en el nombre del ejercicio.
  /// [page] controla el offset de paginación.
  Future<List<AdminEjercicio>> listarEjercicios({
    int page = 0,
    String? query,
    int limit = 30,
  }) async {
    var select = _client.from('ejercicios').select(
          'id, nombre, activo, dificultad, finalidad, modalidad_entrenamiento, tipo_medicion',
        );

    if (query != null && query.isNotEmpty) {
      select = select.ilike('nombre', '%$query%');
    }

    final data = await select
        .order('nombre')
        .range(page * limit, (page + 1) * limit - 1)
        .timeout(const Duration(seconds: 10));

    return (data as List)
        .map((r) => AdminEjercicio.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Activa o desactiva un ejercicio cambiando el flag [activo].
  Future<void> toggleActivo(String id, bool activo) async {
    await _client
        .from('ejercicios')
        .update({'activo': activo})
        .eq('id', id)
        .timeout(const Duration(seconds: 10));
  }

  /// Actualiza campos editables de un ejercicio (nombre, dificultad).
  Future<void> actualizarEjercicio(
    String id, {
    String? nombre,
    String? dificultad,
    String? modalidadEntrenamiento,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (dificultad != null) data['dificultad'] = dificultad;
    if (modalidadEntrenamiento != null) {
      data['modalidad_entrenamiento'] = modalidadEntrenamiento;
    }
    if (data.isEmpty) return;
    await _client
        .from('ejercicios')
        .update(data)
        .eq('id', id)
        .timeout(const Duration(seconds: 10));
  }
}
