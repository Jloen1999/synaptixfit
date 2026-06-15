import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../auth/infrastructure/bienestar_repository.dart';
import '../../auth/infrastructure/objetivo_ia_service.dart';

export '../../auth/infrastructure/bienestar_repository.dart'
    show BienestarRepository;
export '../../auth/infrastructure/objetivo_ia_service.dart'
    show ObjetivoIaService;

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
          rol: 'usuario',
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

// ───────────────────────────────────────────────────────────────────────────
// Proveedor del repositorio de bienestar (rompe dependencia directa
// presentation → infrastructure en perfil_screen.dart).
// ───────────────────────────────────────────────────────────────────────────

/// Carreras del usuario con sus asignaturas del catálogo, para la sección
/// de Estadísticas del perfil.
/// Intenta primero `usuario_carreras` (FK); si está vacío, cae en el texto
/// guardado en `perfil_academico_usuario.carrera` y busca por nombre.
final carreraConAsignaturasProvider =
    FutureProvider<List<({CarreraDb carrera, List<AsignaturaCatalogoDb> subjects})>>(
        (ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  // 1. Intentar por usuario_carreras (FK)
  final ucList = await client
      .from('usuario_carreras')
      .select('carrera_id')
      .eq('usuario_id', user.id);
  var carreraIds = (ucList as List).map((r) => r['carrera_id'] as String).toList();

  // 2. Fallback: buscar carrera por nombre desde perfil_academico_usuario
  if (carreraIds.isEmpty) {
    final perfilAcademico = await client
        .from('perfil_academico_usuario')
        .select('carrera')
        .eq('usuario_id', user.id)
        .maybeSingle();
    final nombreCarrera = perfilAcademico?['carrera'] as String?;
    if (nombreCarrera == null || nombreCarrera.isEmpty) return [];

    final match = await client
        .from('carreras')
        .select('id')
        .eq('nombre', nombreCarrera)
        .maybeSingle();
    if (match != null) {
      carreraIds = [match['id'] as String];
    }
    if (carreraIds.isEmpty) return [];
  }

  // 3. Obtener datos de carreras
  final carrerasData = <Map<String, dynamic>>[];
  for (final cid in carreraIds) {
    final c = await client
        .from('carreras')
        .select()
        .eq('id', cid)
        .maybeSingle();
    if (c != null) carrerasData.add(c);
  }
  final carrerasMap = {
    for (final c in carrerasData) c['id'] as String: CarreraDb.fromMap(c)
  };

  // 4. Obtener asignaturas para todas las carreras
  final subjectsData = <Map<String, dynamic>>[];
  for (final cid in carreraIds) {
    final s = await client
        .from('asignaturas_catalogo')
        .select()
        .eq('carrera_id', cid)
        .order('curso', ascending: true)
        .order('nombre', ascending: true);
    subjectsData.addAll((s as List).cast<Map<String, dynamic>>());
  }

  // 5. Agrupar por carrera
  final subjectsPorCarrera = <String, List<AsignaturaCatalogoDb>>{};
  for (final s in (subjectsData as List)) {
    final sub = AsignaturaCatalogoDb.fromMap(s);
    subjectsPorCarrera.putIfAbsent(sub.carreraId, () => []).add(sub);
  }

  // 6. Construir resultado
  final result = <({CarreraDb carrera, List<AsignaturaCatalogoDb> subjects})>[];
  for (final cid in carreraIds) {
    final carrera = carrerasMap[cid];
    if (carrera == null) continue;
    result.add((
      carrera: carrera,
      subjects: subjectsPorCarrera[cid] ?? [],
    ));
  }
  return result;
});

/// Expone una instancia del repositorio de bienestar para que las pantallas
/// de presentacion no importen directamente la capa de infraestructura.
final bienestarRepositoryProvider = Provider<BienestarRepository>((ref) {
  return const BienestarRepository();
});

/// Expone una instancia del servicio de sugerencias de objetivos via IA.
final objetivoIaServiceProvider = Provider<ObjetivoIaService>((ref) {
  return ObjetivoIaService();
});

/// Asignaturas del catálogo con semestre=0 que el usuario ha mapeado a un curso+semestre
final asignaturasUsuarioSemestreProvider =
    FutureProvider<List<AsignaturaUsuarioSemestreDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];
  final resp = await client
      .from('asignaturas_usuario_semestre')
      .select()
      .eq('usuario_id', user.id);
  return (resp as List).map((r) => AsignaturaUsuarioSemestreDb.fromMap(r)).toList();
});

/// Asignaturas del catálogo con semestre=0 (optativas sin temporalidad)
final asignaturasSinSemestreProvider =
    FutureProvider<List<AsignaturaCatalogoDb>>((ref) async {
  final carreraIds = await _getCarrerasUsuario();
  if (carreraIds.isEmpty) return [];
  final subjects = <AsignaturaCatalogoDb>[];
  for (final cid in carreraIds) {
    final resp = await Supabase.instance.client
        .from('asignaturas_catalogo')
        .select()
        .eq('carrera_id', cid)
        .eq('semestre', 0)
        .order('nombre');
    for (final s in (resp as List)) {
      subjects.add(AsignaturaCatalogoDb.fromMap(s));
    }
  }
  return subjects;
});

/// Helper compartido que devuelve los carrera_ids del usuario
Future<List<String>> _getCarrerasUsuario() async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];
  final ucList = await client
      .from('usuario_carreras')
      .select('carrera_id')
      .eq('usuario_id', user.id);
  var ids = (ucList as List).map((r) => r['carrera_id'] as String).toList();
  if (ids.isEmpty) {
    final perfil = await client
        .from('perfil_academico_usuario')
        .select('carrera')
        .eq('usuario_id', user.id)
        .maybeSingle();
    final nombre = perfil?['carrera'] as String?;
    if (nombre != null && nombre.isNotEmpty) {
      final match = await client
          .from('carreras')
          .select('id')
          .eq('nombre', nombre)
          .maybeSingle();
      if (match != null) ids = [match['id'] as String];
    }
  }
  return ids;
}
