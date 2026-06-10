import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

/// Tipos de cambios que pueden ocurrir en el perfil para invalidación selectiva.
enum PerfilCambio { nombre, bienestar, preferencias, academico, todo }

class PerfilUsuario {
  const PerfilUsuario({required this.usuario, required this.perfil});

  final UsuarioDb usuario;
  final PerfilBienestarDb perfil;
}

class PerfilBienestarCompleto {
  const PerfilBienestarCompleto({
    required this.perfil,
    required this.historial,
  });

  final PerfilBienestarDb perfil;
  final List<HistorialPesoDb> historial;
}

class PerfilActividad {
  const PerfilActividad({
    required this.sesiones,
    required this.logros,
    required this.caloriasAcumuladas,
  });

  final int sesiones;
  final int logros;
  final int caloriasAcumuladas;
}

// ───────────────────────────────────────────────────────────────────────────
// Proveedores enfocados — invalidación selectiva sin recargar todo el perfil
// ───────────────────────────────────────────────────────────────────────────

/// Usuario + perfil bienestar (usados juntos en HeroHeader).
final perfilUsuarioProvider = FutureProvider<PerfilUsuario>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) throw Exception('Sesión no activa');

  final usuarioMap =
      await client.from('usuarios').select().eq('id', user.id).maybeSingle();
  final usuario = usuarioMap != null
      ? UsuarioDb.fromMap(usuarioMap)
      : UsuarioDb(
          id: user.id,
          email: user.email ?? '',
          nombreCompleto: user.userMetadata?['full_name']?.toString() ?? '—',
          urlAvatar: user.userMetadata?['avatar_url']?.toString(),
          nivel: 1,
          xpTotal: 0,
          rachaActual: 0,
          creadoEn: DateTime.now(),
          actualizadoEn: DateTime.now(),
        );

  final perfilMap = await client
      .from('perfil_bienestar_usuario')
      .select()
      .eq('usuario_id', user.id)
      .maybeSingle();
  final perfil = perfilMap != null
      ? PerfilBienestarDb.fromMap(perfilMap)
      : PerfilBienestarDb(
          id: '',
          usuarioId: user.id,
          edad: 0,
          sexo: 'prefiero_no_decirlo',
          pesoKg: 0,
          alturaCm: 0,
          imc: 0,
          nivelActividad: 'sedentario',
          objetivoPrincipal: 'fitness_general',
          objetivos: const [],
          equipamientoDisponible: const [],
          diasDisponiblesSemana: 0,
          minutosPorSesion: 0,
          onboardingCompletado: false,
          creadoEn: DateTime.now(),
          actualizadoEn: DateTime.now(),
        );

  return PerfilUsuario(usuario: usuario, perfil: perfil);
});

/// Perfil bienestar + historial peso (BienestarTab).
final perfilBienestarCompletoProvider =
    FutureProvider<PerfilBienestarCompleto?>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final perfilMap = await client
      .from('perfil_bienestar_usuario')
      .select()
      .eq('usuario_id', user.id)
      .maybeSingle();

  final perfil =
      perfilMap != null ? PerfilBienestarDb.fromMap(perfilMap) : null;

  final historialData = await client
      .from('historial_peso')
      .select()
      .eq('usuario_id', user.id)
      .order('registrado_en', ascending: false);
  final historial =
      historialData.map((e) => HistorialPesoDb.fromMap(e)).toList();

  if (perfil == null) return null;
  return PerfilBienestarCompleto(perfil: perfil, historial: historial);
});

/// Sesiones, logros, calorías (EstadísticasTab).
final perfilActividadProvider = FutureProvider<PerfilActividad>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    return const PerfilActividad(sesiones: 0, logros: 0, caloriasAcumuladas: 0);
  }

  final results = await Future.wait([
    client.from('sesiones_registradas').select('id').eq('usuario_id', user.id),
    client
        .from('sesiones_registradas')
        .select('calorias_quemadas')
        .eq('usuario_id', user.id),
    client
        .from('retos')
        .select('id')
        .eq('usuario_id', user.id)
        .eq('esta_completado', true),
  ]);

  final sesiones = (results[0] as List).length;
  final caloriasAcumuladas = (results[1] as List?)
          ?.fold<double>(
              0,
              (sum, s) =>
                  sum + ((s['calorias_quemadas'] as num?)?.toDouble() ?? 0))
          .round() ??
      0;
  final logros = (results[2] as List).length;

  return PerfilActividad(
      sesiones: sesiones,
      logros: logros,
      caloriasAcumuladas: caloriasAcumuladas);
});

/// Perfil académico (AcademicoTab).
final perfilAcademicoProvider = FutureProvider<PerfilAcademicoDb?>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final data = await client
      .from('perfil_academico_usuario')
      .select()
      .eq('usuario_id', user.id)
      .maybeSingle();

  if (data == null) return null;
  return PerfilAcademicoDb.fromMap(data);
});

/// Preferencias de notificación (AjustesTab).
final perfilPreferenciasProvider =
    FutureProvider<PreferenciasNotificacionDb>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    return PreferenciasNotificacionDb(
      id: '',
      usuarioId: '',
      categoriasActivas: const [],
      limiteDiario: 10,
      modoActual: 'normal',
      creadoEn: DateTime.now(),
      actualizadoEn: DateTime.now(),
    );
  }

  final prefsData = await client
      .from('preferencias_notificacion')
      .select()
      .eq('usuario_id', user.id)
      .maybeSingle();

  return prefsData != null
      ? PreferenciasNotificacionDb.fromMap(prefsData)
      : PreferenciasNotificacionDb(
          id: '',
          usuarioId: '',
          categoriasActivas: const [],
          limiteDiario: 10,
          modoActual: 'normal',
          creadoEn: DateTime.now(),
          actualizadoEn: DateTime.now(),
        );
});

// ───────────────────────────────────────────────────────────────────────────
// Provider compuesto (solo para compatibilidad con el resto de la app)
// ───────────────────────────────────────────────────────────────────────────

class PerfilCompleto {
  const PerfilCompleto({
    required this.usuario,
    required this.perfil,
    required this.sesiones,
    required this.logros,
    required this.caloriasAcumuladas,
    required this.historial,
    required this.preferencias,
  });

  final UsuarioDb usuario;
  final PerfilBienestarDb perfil;
  final int sesiones;
  final int logros;
  final int caloriasAcumuladas;
  final List<HistorialPesoDb> historial;
  final PreferenciasNotificacionDb preferencias;
}

/// Provider compuesto — delegando en los proveedores enfocados.
/// Cada sub-provider está cacheado individualmente.
final perfilCompletoProvider = FutureProvider<PerfilCompleto>((ref) async {
  final usuarioData = await ref.watch(perfilUsuarioProvider.future);
  final actividad = await ref.watch(perfilActividadProvider.future);
  final prefsAsync = ref.watch(perfilPreferenciasProvider);
  final bienestarAsync = ref.watch(perfilBienestarCompletoProvider);

  // No hacer .future sobre FutureProvider dentro de otro FutureProvider
  // porque necesitamos que se ejecuten en paralelo.
  // En su lugar, recomponemos desde los valores cacheados.
  final prefs = prefsAsync.valueOrNull ??
      PreferenciasNotificacionDb(
        id: '',
        usuarioId: '',
        categoriasActivas: const [],
        limiteDiario: 10,
        modoActual: 'normal',
        creadoEn: DateTime.now(),
        actualizadoEn: DateTime.now(),
      );
  final bienestar = bienestarAsync.valueOrNull;

  // Este provider se usa solo para compatibilidad con pantallas que
  // consumen el compuesto. La pantalla de perfil usa ahora los providers
  // individuales para invalidación selectiva.
  return PerfilCompleto(
    usuario: usuarioData.usuario,
    perfil: bienestar?.perfil ?? usuarioData.perfil,
    sesiones: actividad.sesiones,
    logros: actividad.logros,
    caloriasAcumuladas: actividad.caloriasAcumuladas,
    historial: bienestar?.historial ?? [],
    preferencias: prefs,
  );
});
