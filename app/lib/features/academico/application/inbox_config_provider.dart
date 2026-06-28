import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/calendar_dtos.dart';

/// Notifier que gestiona la configuración del inbox (objetivos de la semana).
class InboxConfigNotifier extends StateNotifier<InboxConfig> {
  InboxConfigNotifier() : super(const InboxConfig());

  void setHorasEstudio(double horas) {
    state = state.copyWith(
      horasEstudioObjetivo: horas.clamp(0, 80),
    );
  }

  void setSesionesDeporte(int sesiones) {
    state = state.copyWith(
      sesionesDeporteObjetivo: sesiones.clamp(0, 7),
    );
  }

  void setMinutosPorSesion(int minutos) {
    state = state.copyWith(
      minutosPorSesionDeporte: minutos.clamp(30, 120),
    );
  }

  void addEntrega(EntregaItem entrega) {
    state = state.copyWith(entregas: [...state.entregas, entrega]);
  }

  void removeEntrega(String id) {
    state = state.copyWith(
      entregas: state.entregas.where((e) => e.id != id).toList(),
    );
  }

  void setHorariosFijos(List<HorarioFijoItem> fijos) {
    state = state.copyWith(horariosFijos: fijos);
  }

  void setAsignaturasActivas(List<AsignaturaActivaItem> asignaturas) {
    state = state.copyWith(asignaturasActivas: asignaturas);
  }

  void setRutinasActivas(List<RutinaActivaItem> rutinas) {
    state = state.copyWith(rutinasActivas: rutinas);
  }

  void reset() {
    state = const InboxConfig();
  }

  bool get isConfigured =>
      state.horasEstudioObjetivo > 0 || state.sesionesDeporteObjetivo > 0;
}

/// Configuración actual del inbox (objetivos de la semana).
final inboxConfigProvider =
    StateNotifierProvider<InboxConfigNotifier, InboxConfig>((ref) {
  return InboxConfigNotifier();
});

/// Carga las entregas pendientes del usuario para la semana.
final entregasPendientesProvider =
    FutureProvider<List<EntregaItem>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final now = DateTime.now();
  final inicio = now.subtract(Duration(days: now.weekday - 1));
  final fin = inicio.add(const Duration(days: 6));

  final data = await client
      .from('entregas_examenes')
      .select('*, asignaturas(nombre)')
      .eq('usuario_id', user.id)
      .gte('fecha_limite', inicio.toIso8601String().split('T')[0])
      .lte('fecha_limite', fin.toIso8601String().split('T')[0])
      .eq('esta_completado', false)
      .order('fecha_limite', ascending: true);

  return (data as List).map((e) {
    final map = e as Map<String, dynamic>;
    final asignaturas = map['asignaturas'];
    return EntregaItem(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      tipo: map['tipo'] as String? ?? 'entrega',
      fechaLimite: DateTime.parse(map['fecha_limite'] as String),
      dificultad: map['dificultad'] as String? ?? 'media',
      asignaturaId: map['asignatura_id'] as String?,
      asignaturaNombre:
          asignaturas is Map ? asignaturas['nombre'] as String? : null,
    );
  }).toList();
});

/// Carga las asignaturas activas del usuario para el prompt de IA.
final asignaturasActivasInboxProvider =
    FutureProvider<List<AsignaturaActivaItem>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('asignaturas')
      .select()
      .eq('usuario_id', user.id)
      .eq('archivado', false)
      .order('nombre', ascending: true);

  return (data as List).map((e) {
    final map = e as Map<String, dynamic>;
    return AsignaturaActivaItem(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      creditos: (map['creditos'] as num?)?.toDouble() ?? 3.0,
      dificultad: map['dificultad'] as String? ?? 'media',
    );
  }).toList();
});

/// Carga las rutinas activas del usuario para el prompt de IA.
final rutinasActivasInboxProvider =
    FutureProvider<List<RutinaActivaItem>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('rutinas')
      .select()
      .eq('usuario_id', user.id)
      .eq('estado', 'activo')
      .order('creado_en', ascending: false)
      .limit(5);

  return (data as List).map((e) {
    final map = e as Map<String, dynamic>;
    return RutinaActivaItem(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      objetivo: map['objetivo'] as String? ?? '',
      duracionSemanas: (map['duracion_semanas'] as num?)?.toInt() ?? 1,
      cantidadEjercicios: (map['cantidad_ejercicios'] as num?)?.toInt() ?? 0,
    );
  }).toList();
});

/// Carga los horarios fijos del usuario (clases, sueño, comidas).
final horariosFijosProvider =
    FutureProvider<List<HorarioFijoItem>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('horarios_academicos')
      .select('*, asignaturas(nombre)')
      .eq('usuario_id', user.id)
      .eq('es_fijo', true)
      .order('dia_semana', ascending: true)
      .order('hora_inicio', ascending: true);

  return (data as List).map((e) {
    final map = e as Map<String, dynamic>;
    final horaInicio = DateTime.parse(map['hora_inicio'] as String);
    final horaFin = DateTime.parse(map['hora_fin'] as String);
    final tipoStr = map['tipo_actividad'] as String? ?? 'clase';
    final asigJoin = map['asignaturas'];
    TimeBlockTipo tipo;
    switch (tipoStr) {
      case 'deporte':
        tipo = TimeBlockTipo.deporte;
        break;
      case 'descanso':
        tipo = TimeBlockTipo.descanso;
        break;
      case 'examen':
        tipo = TimeBlockTipo.examen;
        break;
      case 'entrega':
        tipo = TimeBlockTipo.entrega;
        break;
      case 'estudio':
        tipo = TimeBlockTipo.estudio;
        break;
      case 'comida':
        tipo = TimeBlockTipo.comida;
        break;
      case 'sueno':
        tipo = TimeBlockTipo.sueno;
        break;
      default:
        tipo = TimeBlockTipo.clase;
    }
    return HorarioFijoItem(
      id: map['id'] as String,
      diaSemana: map['dia_semana'] ?? horaInicio.weekday,
      horaInicio: TimeOfDay.fromDateTime(horaInicio),
      horaFin: TimeOfDay.fromDateTime(horaFin),
      tipo: tipo,
      titulo: map['temas'] as String? ?? tipoStr,
      asignaturaId: map['asignatura_id'] as String?,
      asignaturaNombre: asigJoin is Map ? asigJoin['nombre'] as String? : null,
      ubicacion: map['ubicacion'] as String?,
      completado: (map['completado'] as bool?) ?? false,
    );
  }).toList();
});
