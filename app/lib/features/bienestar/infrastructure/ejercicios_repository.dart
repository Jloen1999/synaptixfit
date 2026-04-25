import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/catalogo_models.dart';
import '../../../shared/models/db_models.dart';

// ---------------------------------------------------------------------------
// Repositorio de ejercicios — conecta directamente con Supabase.
// Consulta la vista `v_ejercicios_completos` para obtener datos denormalizados.
// ---------------------------------------------------------------------------

class EjerciciosRepository {
  EjerciciosRepository(this._client);

  final SupabaseClient _client;

  // ─────────────────────────────────────────────────────────────────────────
  // Ejercicios
  // ─────────────────────────────────────────────────────────────────────────

  /// Obtiene todos los ejercicios denormalizados, ordenados por nombre.
  Future<List<EjercicioDb>> fetchAll() async {
    final response = await _client
        .from('v_ejercicios_completos')
        .select()
        .order('nombre', ascending: true);

    return (response as List)
        .map((row) => EjercicioDb.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene un ejercicio por su UUID.
  Future<EjercicioDb?> fetchById(String id) async {
    try {
      final response = await _client
          .from('v_ejercicios_completos')
          .select()
          .eq('id', id)
          .single();

      return EjercicioDb.fromMap(response);
    } catch (_) {
      return null;
    }
  }

  /// Filtra ejercicios por parte del cuerpo.
  Future<List<EjercicioDb>> fetchByParteCuerpo(String parte) async {
    // Usamos la vista y filtramos con cs (contains) en el array
    final response = await _client
        .from('v_ejercicios_completos')
        .select()
        .contains('partes_cuerpo', [parte])
        .order('nombre', ascending: true);

    return (response as List)
        .map((row) => EjercicioDb.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Filtra ejercicios por músculo objetivo.
  Future<List<EjercicioDb>> fetchByMusculo(String musculo) async {
    final response = await _client
        .from('v_ejercicios_completos')
        .select()
        .contains('musculos_objetivo', [musculo])
        .order('nombre', ascending: true);

    return (response as List)
        .map((row) => EjercicioDb.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Filtra ejercicios por equipamiento.
  Future<List<EjercicioDb>> fetchByEquipamiento(String equip) async {
    final response = await _client
        .from('v_ejercicios_completos')
        .select()
        .contains('equipamientos', [equip])
        .order('nombre', ascending: true);

    return (response as List)
        .map((row) => EjercicioDb.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Búsqueda full-text en español sobre nombre y descripción.
  Future<List<EjercicioDb>> buscar(String query) async {
    if (query.trim().isEmpty) return fetchAll();

    // Usamos textSearch con la configuración 'spanish'
    final response = await _client
        .from('v_ejercicios_completos')
        .select()
        .textSearch('nombre', query, config: 'spanish')
        .order('nombre', ascending: true);

    return (response as List)
        .map((row) => EjercicioDb.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Catálogos
  // ─────────────────────────────────────────────────────────────────────────

  /// Carga los 3 catálogos (partes del cuerpo, músculos, equipamientos).
  Future<CatalogosEjercicios> fetchCatalogos() async {
    final results = await Future.wait([
      _client.from('partes_cuerpo').select().order('nombre'),
      _client.from('musculos').select().order('nombre'),
      _client.from('equipamientos').select().order('nombre'),
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
}
