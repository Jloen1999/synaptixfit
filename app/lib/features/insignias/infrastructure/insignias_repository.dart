import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/insignia_dto.dart';

/// Acceso a datos de insignias (catálogo + usuario_insignias).
class InsigniasRepository {
  final SupabaseClient _client;

  const InsigniasRepository(this._client);

  /// Obtiene el catálogo completo de insignias, marcando cuáles tiene el usuario.
  Future<List<Insignia>> obtenerCatalogo(String usuarioId) async {
    // 1. Catálogo completo
    final catalogoData = await _client
        .from('insignias')
        .select()
        .order('orden', ascending: true);

    // 2. Insignias ya obtenidas por el usuario
    final obtenidasData = await _client
        .from('usuario_insignias')
        .select('insignia_id, obtenida_en')
        .eq('usuario_id', usuarioId);

    final obtenidasMap = <String, DateTime>{};
    for (final row in (obtenidasData as List)) {
      final map = row as Map<String, dynamic>;
      final insId = map['insignia_id'] as String;
      final fecha = map['obtenida_en'] != null
          ? DateTime.tryParse(map['obtenida_en'].toString())
          : null;
      if (fecha != null) obtenidasMap[insId] = fecha;
    }

    return (catalogoData as List).map((row) {
      final map = row as Map<String, dynamic>;
      final insId = map['id'] as String;
      final obtenida = obtenidasMap.containsKey(insId);
      return Insignia.fromMap(
        map,
        obtenida: obtenida,
        obtenidaEn: obtenidasMap[insId],
      );
    }).toList();
  }

  /// Obtiene solo las insignias que el usuario ya ha desbloqueado.
  Future<List<Insignia>> obtenerInsigniasUsuario(String usuarioId) async {
    final data = await _client
        .from('usuario_insignias')
        .select('id, obtenida_en, insignias!inner(*)')
        .eq('usuario_id', usuarioId)
        .order('obtenida_en', ascending: false);

    if (data.isEmpty) return [];

    return (data as List).map((row) {
      final map = row as Map<String, dynamic>;
      final insData = map['insignias'] as Map<String, dynamic>;
      final obtenidaEn = DateTime.tryParse(map['obtenida_en'].toString());
      return Insignia.fromMap(insData, obtenida: true, obtenidaEn: obtenidaEn);
    }).toList();
  }

  /// Otorga una insignia al usuario. Retorna true si se insertó (no la tenía).
  Future<bool> otorgarInsignia(String usuarioId, String insigniaId) async {
    try {
      await _client.from('usuario_insignias').insert({
        'usuario_id': usuarioId,
        'insignia_id': insigniaId,
      });
      return true;
    } on PostgrestException catch (e) {
      // Si ya existe, el UNIQUE constraint lo impide — no es error real.
      if (e.code == '23505') return false;
      rethrow;
    }
  }

  /// Marca una insignia como notificada (para que no vuelva a mostrar toast).
  Future<void> marcarNotificada(String usuarioInsigniaId) async {
    await _client
        .from('usuario_insignias')
        .update({'notificada': true}).eq('id', usuarioInsigniaId);
  }
}
