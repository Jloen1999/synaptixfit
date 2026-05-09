import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/catalogo_models.dart';
import '../../../shared/models/db_models.dart';

// ---------------------------------------------------------------------------
// Repositorio de ejercicios — conecta directamente con Supabase.
// Consulta la vista `v_ejercicios_completos` para obtener datos denormalizados.
// Soporta paginación opcional.
// ---------------------------------------------------------------------------

const _tamanoPagina = 50;

/// Columnas mínimas necesarias del view para ahorrar ancho de banda.
const _columnasEjercicio = 'id,exercise_db_id,nombre,url_gif,instrucciones,'
    'dificultad,descripcion,partes_cuerpo,musculos_objetivo,'
    'musculos_secundarios,equipamientos,creado_en,actualizado_en';

class EjerciciosRepository {
  EjerciciosRepository(this._client);

  final SupabaseClient _client;

  // ─────────────────────────────────────────────────────────────────────────
  // Ejercicios — fetch único (paginado opcional)
  // ─────────────────────────────────────────────────────────────────────────

  /// Obtiene todos los ejercicios denormalizados, ordenados por nombre.
  /// [pagina] 1-indexada. Si es null se devuelven todos de una vez.
  Future<List<EjercicioDb>> fetchAll({int? pagina}) async {
    var query = _client
        .from('v_ejercicios_completos')
        .select(_columnasEjercicio)
        .order('nombre', ascending: true);

    if (pagina != null) {
      query = query.range(
        (pagina - 1) * _tamanoPagina,
        pagina * _tamanoPagina - 1,
      );
    } else {
      query = query.limit(10000);
    }

    final response = await query;
    return _mapearLista(response);
  }

  /// Obtiene un ejercicio por su UUID.
  Future<EjercicioDb?> fetchById(String id) async {
    try {
      final response = await _client
          .from('v_ejercicios_completos')
          .select(_columnasEjercicio)
          .eq('id', id)
          .single();

      return EjercicioDb.fromMap(response);
    } catch (_) {
      return null;
    }
  }

  /// Filtra ejercicios por parte del cuerpo.
  Future<List<EjercicioDb>> fetchByParteCuerpo(String parte) async {
    final response = await _client
        .from('v_ejercicios_completos')
        .select(_columnasEjercicio)
        .contains('partes_cuerpo', [parte])
        .order('nombre', ascending: true)
        .limit(10000);

    return _mapearLista(response);
  }

  /// Filtra ejercicios por músculo objetivo.
  Future<List<EjercicioDb>> fetchByMusculo(String musculo) async {
    final response = await _client
        .from('v_ejercicios_completos')
        .select(_columnasEjercicio)
        .contains('musculos_objetivo', [musculo])
        .order('nombre', ascending: true)
        .limit(10000);

    return _mapearLista(response);
  }

  /// Filtra ejercicios por equipamiento.
  Future<List<EjercicioDb>> fetchByEquipamiento(String equip) async {
    final response = await _client
        .from('v_ejercicios_completos')
        .select(_columnasEjercicio)
        .contains('equipamientos', [equip])
        .order('nombre', ascending: true)
        .limit(10000);

    return _mapearLista(response);
  }

  /// Búsqueda full-text en español sobre nombre y descripción.
  Future<List<EjercicioDb>> buscar(String query) async {
    if (query.trim().isEmpty) return fetchAll();

    final response = await _client
        .from('v_ejercicios_completos')
        .select(_columnasEjercicio)
        .textSearch('nombre', query, config: 'spanish')
        .order('nombre', ascending: true)
        .limit(10000);

    return _mapearLista(response);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Catálogos
  // ─────────────────────────────────────────────────────────────────────────

  /// Carga los 3 catálogos (partes del cuerpo, músculos, equipamientos).
  Future<CatalogosEjercicios> fetchCatalogos() async {
    final results = await Future.wait([
      _client.from('partes_cuerpo').select('id,nombre').order('nombre'),
      _client.from('musculos').select('id,nombre').order('nombre'),
      _client.from('equipamientos').select('id,nombre').order('nombre'),
    ]);

    return CatalogosEjercicios(
      partesCuerpo: (results[0] as List)
          .map((r) => ParteCuerpoDb.fromMap(r as Map<String, dynamic>))
          .toList(),
      musculos: (results[1] as List)
          .map((r) => MusculoDb.fromMap(r as Map<String, dynamic>))
          .toList(),
      equipamientos: (results[2] as List)
          .map((r) => EquipamientoDb.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  List<EjercicioDb> _mapearLista(dynamic response) {
    return (response as List)
        .map((row) => EjercicioDb.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
