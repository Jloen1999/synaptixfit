import 'package:flutter/material.dart';

// =============================================================================
// Enums
// =============================================================================

/// Tipos de bloque en el grid semanal de time-blocking.
enum TimeBlockTipo {
  estudio,
  deporte,
  clase,
  descanso,
  comida,
  sueno,
  entrega,
  examen,
  repaso,
}

/// Fase del flujo de planificación semanal.
enum PlanificadorFase { inbox, canvas, guardando, completado }

/// Severidad de un conflicto detectado entre bloques.
enum ConflictSeverity { info, warning, error }

// =============================================================================
// InboxConfig
// =============================================================================

/// Configuración de objetivos y restricciones para generar la semana.
class InboxConfig {
  final double horasEstudioObjetivo;
  final int sesionesDeporteObjetivo;
  final int minutosPorSesionDeporte;
  final int tMaxEstudioMinutos;
  final List<EntregaItem> entregas;
  final List<HorarioFijoItem> horariosFijos;
  final List<AsignaturaActivaItem> asignaturasActivas;
  final List<RutinaActivaItem> rutinasActivas;

  const InboxConfig({
    this.horasEstudioObjetivo = 20.0,
    this.sesionesDeporteObjetivo = 3,
    this.minutosPorSesionDeporte = 60,
    this.tMaxEstudioMinutos = 90,
    this.entregas = const [],
    this.horariosFijos = const [],
    this.asignaturasActivas = const [],
    this.rutinasActivas = const [],
  });

  double get totalHorasDeporteSemana =>
      sesionesDeporteObjetivo * minutosPorSesionDeporte / 60.0;

  InboxConfig copyWith({
    double? horasEstudioObjetivo,
    int? sesionesDeporteObjetivo,
    int? minutosPorSesionDeporte,
    int? tMaxEstudioMinutos,
    List<EntregaItem>? entregas,
    List<HorarioFijoItem>? horariosFijos,
    List<AsignaturaActivaItem>? asignaturasActivas,
    List<RutinaActivaItem>? rutinasActivas,
  }) {
    return InboxConfig(
      horasEstudioObjetivo: horasEstudioObjetivo ?? this.horasEstudioObjetivo,
      sesionesDeporteObjetivo:
          sesionesDeporteObjetivo ?? this.sesionesDeporteObjetivo,
      minutosPorSesionDeporte:
          minutosPorSesionDeporte ?? this.minutosPorSesionDeporte,
      tMaxEstudioMinutos: tMaxEstudioMinutos ?? this.tMaxEstudioMinutos,
      entregas: entregas ?? this.entregas,
      horariosFijos: horariosFijos ?? this.horariosFijos,
      asignaturasActivas: asignaturasActivas ?? this.asignaturasActivas,
      rutinasActivas: rutinasActivas ?? this.rutinasActivas,
    );
  }
}

// =============================================================================
// EntregaItem
// =============================================================================

class EntregaItem {
  final String id;
  final String titulo;
  final String tipo;
  final DateTime fechaLimite;
  final String dificultad;
  final String? asignaturaId;
  final String? asignaturaNombre;

  const EntregaItem({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.fechaLimite,
    required this.dificultad,
    this.asignaturaId,
    this.asignaturaNombre,
  });
}

// =============================================================================
// HorarioFijoItem
// =============================================================================

class HorarioFijoItem {
  final String id;
  final int diaSemana;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFin;
  final TimeBlockTipo tipo;
  final String titulo;
  final String? asignaturaId;
  final String? asignaturaNombre;
  final String? ubicacion;
  final bool completado;

  const HorarioFijoItem({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.tipo,
    required this.titulo,
    this.asignaturaId,
    this.asignaturaNombre,
    this.ubicacion,
    this.completado = false,
  });
}

// =============================================================================
// AsignaturaActivaItem
// =============================================================================

class AsignaturaActivaItem {
  final String id;
  final String nombre;
  final double creditos;
  final String dificultad;

  const AsignaturaActivaItem({
    required this.id,
    required this.nombre,
    required this.creditos,
    required this.dificultad,
  });
}

// =============================================================================
// RutinaActivaItem
// =============================================================================

class RutinaActivaItem {
  final String id;
  final String nombre;
  final String objetivo;
  final int duracionSemanas;
  final int cantidadEjercicios;

  const RutinaActivaItem({
    required this.id,
    required this.nombre,
    required this.objetivo,
    required this.duracionSemanas,
    required this.cantidadEjercicios,
  });
}

// =============================================================================
// TimeBlock
// =============================================================================

/// Bloque visual en el grid semanal.
class TimeBlock {
  final String idLocal;
  final int diaSemana;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFin;
  final TimeBlockTipo tipo;
  final String? titulo;
  final String? asignaturaId;
  final String? asignaturaNombre;
  final String? rutinaId;
  final String? rutinaNombre;
  final String? temas;
  final Color color;
  final bool esFijo;
  final bool esSugerencia;
  final bool aceptado;
  final String? planEstudioId;
  final String? dbId;
  final String? diaRutinaId;
  final String? semanaRutinaId;
  final String? retoId;
  final String? hitoId;
  final String? retoTitulo;
  final DateTime? fecha;
  final bool esHitoInamovible;
  final String? ubicacion;
  final bool completado;

  const TimeBlock({
    required this.idLocal,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.tipo,
    this.titulo,
    this.asignaturaId,
    this.asignaturaNombre,
    this.rutinaId,
    this.rutinaNombre,
    this.temas,
    required this.color,
    this.esFijo = false,
    this.esSugerencia = false,
    this.aceptado = true,
    this.planEstudioId,
    this.dbId,
    this.diaRutinaId,
    this.semanaRutinaId,
    this.retoId,
    this.hitoId,
    this.retoTitulo,
    this.fecha,
    this.esHitoInamovible = false,
    this.ubicacion,
    this.completado = false,
  });

  Duration get duracion {
    final inicioMin = horaInicio.hour * 60 + horaInicio.minute;
    final finMin = horaFin.hour * 60 + horaFin.minute;
    return Duration(minutes: finMin - inicioMin);
  }

  double get duracionHoras => duracion.inMinutes / 60.0;

  int get diaSemanaEfectivo => fecha?.weekday ?? diaSemana;

  TimeBlock copyWith({
    String? idLocal,
    int? diaSemana,
    TimeOfDay? horaInicio,
    TimeOfDay? horaFin,
    TimeBlockTipo? tipo,
    String? titulo,
    String? asignaturaId,
    String? asignaturaNombre,
    String? rutinaId,
    String? rutinaNombre,
    String? temas,
    Color? color,
    bool? esFijo,
    bool? esSugerencia,
    bool? aceptado,
    String? planEstudioId,
    String? dbId,
    String? diaRutinaId,
    String? semanaRutinaId,
    String? retoId,
    String? hitoId,
    String? retoTitulo,
    DateTime? fecha,
    bool? esHitoInamovible,
    String? ubicacion,
    bool? completado,
  }) {
    return TimeBlock(
      idLocal: idLocal ?? this.idLocal,
      diaSemana: diaSemana ?? this.diaSemana,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      asignaturaId: asignaturaId ?? this.asignaturaId,
      asignaturaNombre: asignaturaNombre ?? this.asignaturaNombre,
      rutinaId: rutinaId ?? this.rutinaId,
      rutinaNombre: rutinaNombre ?? this.rutinaNombre,
      temas: temas ?? this.temas,
      color: color ?? this.color,
      esFijo: esFijo ?? this.esFijo,
      esSugerencia: esSugerencia ?? this.esSugerencia,
      aceptado: aceptado ?? this.aceptado,
      planEstudioId: planEstudioId ?? this.planEstudioId,
      dbId: dbId ?? this.dbId,
      diaRutinaId: diaRutinaId ?? this.diaRutinaId,
      semanaRutinaId: semanaRutinaId ?? this.semanaRutinaId,
      retoId: retoId ?? this.retoId,
      hitoId: hitoId ?? this.hitoId,
      retoTitulo: retoTitulo ?? this.retoTitulo,
      fecha: fecha ?? this.fecha,
      esHitoInamovible: esHitoInamovible ?? this.esHitoInamovible,
      ubicacion: ubicacion ?? this.ubicacion,
      completado: completado ?? this.completado,
    );
  }
}

// =============================================================================
// SemanaGenerada
// =============================================================================

class SemanaGenerada {
  final List<DiaGenerado> dias;
  final WeekPlanMetadata metadata;

  const SemanaGenerada({required this.dias, required this.metadata});

  List<BloqueGenerado> get todosLosBloques =>
      dias.expand((d) => d.bloques).toList();

  factory SemanaGenerada.fromJson(Map<String, dynamic> json) {
    final diasMap = {
      'lunes': 1,
      'martes': 2,
      'miercoles': 3,
      'jueves': 4,
      'viernes': 5,
      'sabado': 6,
      'domingo': 7,
    };

    final semana = json['semana'] as Map<String, dynamic>;
    final dias = <DiaGenerado>[];

    for (final entry in diasMap.entries) {
      final diaData = semana[entry.key] as List<dynamic>?;
      if (diaData != null) {
        dias.add(DiaGenerado(
          diaSemana: entry.value,
          bloques: diaData
              .map((b) => BloqueGenerado.fromJson(b as Map<String, dynamic>))
              .toList(),
        ));
      }
    }

    final metadata = json['metadata'] is Map<String, dynamic>
        ? WeekPlanMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
        : const WeekPlanMetadata();

    return SemanaGenerada(dias: dias, metadata: metadata);
  }
}

// =============================================================================
// DiaGenerado
// =============================================================================

class DiaGenerado {
  final int diaSemana;
  final List<BloqueGenerado> bloques;

  const DiaGenerado({required this.diaSemana, required this.bloques});
}

// =============================================================================
// BloqueGenerado
// =============================================================================

class BloqueGenerado {
  final TimeBlockTipo tipo;
  final String horaInicio;
  final String horaFin;
  final String? asignatura;
  final String? tema;
  final String? rutina;

  const BloqueGenerado({
    required this.tipo,
    required this.horaInicio,
    required this.horaFin,
    this.asignatura,
    this.tema,
    this.rutina,
  });

  factory BloqueGenerado.fromJson(Map<String, dynamic> json) {
    final tipoStr = (json['tipo'] as String?) ?? 'estudio';
    TimeBlockTipo tipo;
    switch (tipoStr) {
      case 'deporte':
        tipo = TimeBlockTipo.deporte;
        break;
      case 'clase':
        tipo = TimeBlockTipo.clase;
        break;
      case 'descanso':
        tipo = TimeBlockTipo.descanso;
        break;
      default:
        tipo = TimeBlockTipo.estudio;
    }
    return BloqueGenerado(
      tipo: tipo,
      horaInicio: json['hora_inicio'] as String,
      horaFin: json['hora_fin'] as String,
      asignatura: json['asignatura'] as String?,
      tema: json['tema'] as String?,
      rutina: json['rutina'] as String?,
    );
  }
}

// =============================================================================
// ConflictInfo
// =============================================================================

class ConflictInfo {
  final String bloqueIdA;
  final String bloqueIdB;
  final String descripcion;
  final ConflictSeverity severidad;

  const ConflictInfo({
    required this.bloqueIdA,
    required this.bloqueIdB,
    required this.descripcion,
    this.severidad = ConflictSeverity.warning,
  });
}

// =============================================================================
// WeekPlanMetadata
// =============================================================================

class WeekPlanMetadata {
  final double horasEstudioColocadas;
  final int sesionesDeporteColocadas;
  final double horasDeporteColocadas;
  final double progresoEstudio;
  final double progresoDeporte;
  final int conflictosDetectados;
  final int bloquesTotales;
  final int bloquesAceptados;
  final int bloquesRechazados;

  const WeekPlanMetadata({
    this.horasEstudioColocadas = 0,
    this.sesionesDeporteColocadas = 0,
    this.horasDeporteColocadas = 0,
    this.progresoEstudio = 0,
    this.progresoDeporte = 0,
    this.conflictosDetectados = 0,
    this.bloquesTotales = 0,
    this.bloquesAceptados = 0,
    this.bloquesRechazados = 0,
  });

  factory WeekPlanMetadata.fromJson(Map<String, dynamic> json) {
    return WeekPlanMetadata(
      horasEstudioColocadas:
          (json['horas_estudio_colocadas'] as num?)?.toDouble() ?? 0,
      sesionesDeporteColocadas:
          (json['sesiones_deporte_colocadas'] as num?)?.toInt() ?? 0,
      horasDeporteColocadas:
          (json['horas_deporte_colocadas'] as num?)?.toDouble() ?? 0,
    );
  }
}

// =============================================================================
// CalendarGridState
// =============================================================================

class CalendarGridState {
  final PlanificadorFase fase;
  final InboxConfig config;
  final List<TimeBlock> bloques;
  final List<RetoBanner> retoBanners;
  final String? planId;
  final String? planNombre;
  final DateTime? semanaInicio;
  final DateTime? semanaFin;
  final bool cargandoIa;
  final String? errorIa;
  final bool guardando;
  final String? errorGuardado;
  final WeekPlanMetadata? metadata;
  final int semanaOffset;
  final DateTime fechaInicioPantalla;
  final bool sincronizando;

  CalendarGridState({
    this.fase = PlanificadorFase.inbox,
    this.config = const InboxConfig(),
    this.bloques = const [],
    this.retoBanners = const [],
    this.planId,
    this.planNombre,
    this.semanaInicio,
    this.semanaFin,
    this.cargandoIa = false,
    this.errorIa,
    this.guardando = false,
    this.errorGuardado,
    this.metadata,
    this.semanaOffset = 0,
    DateTime? fechaInicioPantalla,
    this.sincronizando = false,
  }) : fechaInicioPantalla = fechaInicioPantalla ?? DateTime.now();

  DateTime get fechaFinPantalla =>
      fechaInicioPantalla.add(const Duration(days: 6));

  List<TimeBlock> get bloquesNoFijos =>
      bloques.where((b) => !b.esFijo).toList();

  List<TimeBlock> get bloquesFijos => bloques.where((b) => b.esFijo).toList();

  List<TimeBlock> get bloquesSugeridos =>
      bloques.where((b) => b.esSugerencia).toList();

  List<TimeBlock> get bloquesAceptados =>
      bloques.where((b) => b.aceptado && !b.esFijo).toList();

  double get horasEstudioColocadas => bloquesAceptados
      .where((b) => b.tipo == TimeBlockTipo.estudio)
      .fold(0.0, (sum, b) => sum + b.duracionHoras);

  int get sesionesDeporteColocadas =>
      bloquesAceptados.where((b) => b.tipo == TimeBlockTipo.deporte).length;

  CalendarGridState copyWith({
    PlanificadorFase? fase,
    InboxConfig? config,
    List<TimeBlock>? bloques,
    List<RetoBanner>? retoBanners,
    String? planId,
    String? planNombre,
    DateTime? semanaInicio,
    DateTime? semanaFin,
    bool? cargandoIa,
    String? errorIa,
    bool clearErrorIa = false,
    bool? guardando,
    String? errorGuardado,
    bool clearErrorGuardado = false,
    WeekPlanMetadata? metadata,
    int? semanaOffset,
    DateTime? fechaInicioPantalla,
    bool? sincronizando,
  }) {
    return CalendarGridState(
      fase: fase ?? this.fase,
      config: config ?? this.config,
      bloques: bloques ?? this.bloques,
      retoBanners: retoBanners ?? this.retoBanners,
      planId: planId ?? this.planId,
      planNombre: planNombre ?? this.planNombre,
      semanaInicio: semanaInicio ?? this.semanaInicio,
      semanaFin: semanaFin ?? this.semanaFin,
      cargandoIa: cargandoIa ?? this.cargandoIa,
      errorIa: clearErrorIa ? null : errorIa ?? this.errorIa,
      guardando: guardando ?? this.guardando,
      errorGuardado:
          clearErrorGuardado ? null : errorGuardado ?? this.errorGuardado,
      metadata: metadata ?? this.metadata,
      semanaOffset: semanaOffset ?? this.semanaOffset,
      fechaInicioPantalla: fechaInicioPantalla ?? this.fechaInicioPantalla,
      sincronizando: sincronizando ?? this.sincronizando,
    );
  }
}

// =============================================================================
// RetoBanner
// =============================================================================

class RetoBanner {
  final String retoId;
  final String titulo;
  final String? meta;
  final String tipo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool esComplejo;
  final List<RetoTareaBanner> tareas;
  final Color color;
  final double progreso;

  const RetoBanner({
    required this.retoId,
    required this.titulo,
    this.meta,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    this.esComplejo = false,
    this.tareas = const [],
    required this.color,
    this.progreso = 0,
  });

  bool abarcaSemana(DateTime inicioSemana, DateTime finSemana) {
    return fechaInicio.isBefore(finSemana.add(const Duration(days: 1))) &&
        fechaFin.isAfter(inicioSemana.subtract(const Duration(days: 1)));
  }

  int columnaInicio(DateTime inicioSemana) {
    if (fechaInicio.isBefore(inicioSemana)) return 0;
    return fechaInicio.difference(inicioSemana).inDays.clamp(0, 6);
  }

  int columnaFin(DateTime inicioSemana) {
    final finSemana = inicioSemana.add(const Duration(days: 6));
    if (fechaFin.isAfter(finSemana)) return 6;
    return fechaFin.difference(inicioSemana).inDays.clamp(0, 6);
  }
}

// =============================================================================
// RetoTareaBanner
// =============================================================================

class RetoTareaBanner {
  final String hitoId;
  final String titulo;
  final int indiceOrden;
  final double progreso;
  final bool completada;
  final String estado;
  final DateTime? fechaAsignada;

  const RetoTareaBanner({
    required this.hitoId,
    required this.titulo,
    required this.indiceOrden,
    this.progreso = 0,
    this.completada = false,
    this.estado = 'disponible',
    this.fechaAsignada,
  });
}
