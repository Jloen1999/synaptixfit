import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../shared/models/db_models.dart';

/// Repositorio para gestionar el perfil de bienestar del usuario.
///
/// Encapsula las operaciones CRUD sobre `perfil_bienestar_usuario`,
/// `historial_peso` y la actualización de metadata de onboarding.
class BienestarRepository {
  const BienestarRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _asegurarUsuarioBase() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay sesión activa para guardar perfil de bienestar.');
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final nombreDesdeMeta =
        (metadata['full_name'] ?? metadata['name'] ?? '').toString().trim();
    final nombreFallback =
        (user.email ?? 'usuario@local.invalid').split('@').first;
    final nombreCompleto =
        nombreDesdeMeta.isNotEmpty ? nombreDesdeMeta : nombreFallback;
    final avatarUrl =
        metadata['avatar_url']?.toString() ?? metadata['picture']?.toString();

    await _client.from('usuarios').upsert({
      'id': user.id,
      'email': user.email ?? '${user.id}@local.invalid',
      'nombre_completo': nombreCompleto,
      'url_avatar': avatarUrl,
    }, onConflict: 'id');
  }

  // ---------------------------------------------------------------------------
  // guardarPerfilBienestar — INSERT o UPSERT
  // ---------------------------------------------------------------------------
  Future<void> guardarPerfilBienestar({
    required int edad,
    required String sexo,
    String? ciudad,
    required double pesoKg,
    required double alturaCm,
    required String nivelActividad,
    required String objetivoPrincipal,
    List<String> equipamientoDisponible = const [],
    int diasDisponiblesSemana = 3,
    int minutosPorSesion = 45,
  }) async {
    final alturaM = alturaCm / 100;
    final imc = pesoKg / (alturaM * alturaM);

    if (!EnvConfig.hasSupabase) {
      throw Exception('Supabase no configurado.');
    }

    final userId = _client.auth.currentUser!.id;
    await _asegurarUsuarioBase();
    final data = {
      'usuario_id': userId,
      'edad': edad,
      'sexo': sexo,
      'ciudad': ciudad,
      'peso_kg': pesoKg,
      'altura_cm': alturaCm,
      'imc': double.parse(imc.toStringAsFixed(1)),
      'nivel_actividad': nivelActividad,
      'objetivo_principal': objetivoPrincipal,
      'objetivos': [objetivoPrincipal],
      'equipamiento_disponible': equipamientoDisponible,
      'dias_disponibles_semana': diasDisponiblesSemana,
      'minutos_por_sesion': minutosPorSesion,
      'onboarding_completado': true,
    };

    await _client
        .from('perfil_bienestar_usuario')
        .upsert(data, onConflict: 'usuario_id');

    // Registro inicial en historial
    await _client.from('historial_peso').insert({
      'usuario_id': userId,
      'peso_kg': pesoKg,
      'altura_cm': alturaCm,
      'imc': double.parse(imc.toStringAsFixed(1)),
    });
  }

  // ---------------------------------------------------------------------------
  // obtenerPerfilBienestar — SELECT
  // ---------------------------------------------------------------------------
  Future<PerfilBienestarDb?> obtenerPerfilBienestar() async {
    if (!EnvConfig.hasSupabase) return null;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final resultado = await _client
        .from('perfil_bienestar_usuario')
        .select()
        .eq('usuario_id', userId)
        .maybeSingle();

    if (resultado == null) return null;
    return PerfilBienestarDb.fromMap(resultado);
  }

  // ---------------------------------------------------------------------------
  // actualizarPeso — UPDATE perfil + INSERT historial
  // ---------------------------------------------------------------------------
  Future<void> actualizarPeso({
    required double pesoKg,
    required double alturaCm,
  }) async {
    final alturaM = alturaCm / 100;
    final imc = pesoKg / (alturaM * alturaM);
    final imcRedondeado = double.parse(imc.toStringAsFixed(1));

    if (!EnvConfig.hasSupabase) {
      throw Exception('Supabase no configurado.');
    }

    final userId = _client.auth.currentUser!.id;
    await _asegurarUsuarioBase();

    await _client.from('perfil_bienestar_usuario').update({
      'peso_kg': pesoKg,
      'altura_cm': alturaCm,
      'imc': imcRedondeado,
    }).eq('usuario_id', userId);

    await _client.from('historial_peso').insert({
      'usuario_id': userId,
      'peso_kg': pesoKg,
      'altura_cm': alturaCm,
      'imc': imcRedondeado,
    });
  }

  // ---------------------------------------------------------------------------
  // marcarOnboardingCompletado — Actualiza metadata auth.users
  // ---------------------------------------------------------------------------
  Future<void> marcarOnboardingCompletado() async {
    if (!EnvConfig.hasSupabase) {
      debugPrint('[BienestarRepo] Supabase no configurado');
      return;
    }

    await _client.auth.updateUser(
      UserAttributes(
        data: {'onboarding_completado': true},
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // obtenerHistorialPeso — SELECT ordenado por fecha
  // ---------------------------------------------------------------------------
  Future<List<HistorialPesoDb>> obtenerHistorialPeso() async {
    if (!EnvConfig.hasSupabase) return [];

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final resultado = await _client
        .from('historial_peso')
        .select()
        .eq('usuario_id', userId)
        .order('registrado_en', ascending: true);

    return resultado.map((e) => HistorialPesoDb.fromMap(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // actualizarNombre — UPDATE public.usuarios.nombre_completo
  // ---------------------------------------------------------------------------
  Future<void> actualizarNombre(String nombreCompleto) async {
    if (!EnvConfig.hasSupabase) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('usuarios').update({
      'nombre_completo': nombreCompleto,
    }).eq('id', userId);
  }

  // ---------------------------------------------------------------------------
  // actualizarPerfilParcial — UPDATE parcial de perfil_bienestar_usuario
  // ---------------------------------------------------------------------------
  Future<void> actualizarPerfilParcial(Map<String, dynamic> data) async {
    if (!EnvConfig.hasSupabase) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('perfil_bienestar_usuario')
        .update(data)
        .eq('usuario_id', userId);
  }
}
