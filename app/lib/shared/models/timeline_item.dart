import 'package:flutter/material.dart';

import 'db_models.dart';

/// Tipos de items en la linea de tiempo unificada.
enum TimelineTipo {
  estudio, // bloque de estudio
  clase, // clase presencial
  deporte, // sesion de ejercicio
  sesion, // sesion completada
  entrega, // plazo de entrega / examen
  reto, // reto activo
  hitoReto, // tarea individual de un reto complejo
  entrenamientoPendiente, // dia de rutina pendiente
  nutricion, // FUTURIBLE
  sueno, // FUTURIBLE
}

extension TimelineTipoX on TimelineTipo {
  Color get color => switch (this) {
        TimelineTipo.estudio => const Color(0xFF3B82F6),
        TimelineTipo.clase => const Color(0xFF8B5CF6),
        TimelineTipo.deporte => const Color(0xFFFF8C42),
        TimelineTipo.sesion => const Color(0xFF10B981),
        TimelineTipo.entrega => const Color(0xFFE74C3C),
        TimelineTipo.reto => const Color(0xFF7C4DFF),
        TimelineTipo.hitoReto => const Color(0xFF7C4DFF),
        TimelineTipo.entrenamientoPendiente => const Color(0xFFFF8C42),
        TimelineTipo.nutricion => const Color(0xFF00BCD4),
        TimelineTipo.sueno => const Color(0xFF3F51B5),
      };

  IconData get icono => switch (this) {
        TimelineTipo.estudio => Icons.menu_book_rounded,
        TimelineTipo.clase => Icons.school_rounded,
        TimelineTipo.deporte => Icons.fitness_center_rounded,
        TimelineTipo.sesion => Icons.check_circle_rounded,
        TimelineTipo.entrega => Icons.assignment_turned_in_rounded,
        TimelineTipo.reto => Icons.emoji_events_rounded,
        TimelineTipo.hitoReto => Icons.task_alt_rounded,
        TimelineTipo.entrenamientoPendiente => Icons.fitness_center_rounded,
        TimelineTipo.nutricion => Icons.restaurant_rounded,
        TimelineTipo.sueno => Icons.bedtime_rounded,
      };

  String get label => switch (this) {
        TimelineTipo.estudio => 'Estudio',
        TimelineTipo.clase => 'Clase',
        TimelineTipo.deporte => 'Deporte',
        TimelineTipo.sesion => 'Sesion',
        TimelineTipo.entrega => 'Entrega',
        TimelineTipo.reto => 'Reto',
        TimelineTipo.hitoReto => 'Tarea',
        TimelineTipo.entrenamientoPendiente => 'Pendiente',
        TimelineTipo.nutricion => 'Nutricion',
        TimelineTipo.sueno => 'Sueno',
      };
}

/// Item unificado de la linea de tiempo.
class TimelineItem {
  final String id;
  final TimelineTipo tipo;
  final String titulo;
  final String subtitulo;
  final DateTime horaInicio;
  final DateTime horaFin;
  final bool completado;
  final Object? datosOriginales;
  final int? duracionMinutos;
  final int? rpe;
  final int? diasRestantes;
  final String? rutinaId;

  const TimelineItem({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.subtitulo = '',
    required this.horaInicio,
    required this.horaFin,
    this.completado = false,
    this.datosOriginales,
    this.duracionMinutos,
    this.rpe,
    this.diasRestantes,
    this.rutinaId,
  });

  /// Punto temporal de referencia para ordenacion.
  DateTime get referenciaTemporal =>
      tipo == TimelineTipo.entrega ? horaFin : horaInicio;

  factory TimelineItem.desdeHorario(HorarioAcademicoDb h) {
    final tipo = switch (h.tipoActividad) {
      'clase' => TimelineTipo.clase,
      'deporte' => TimelineTipo.deporte,
      'examen' => TimelineTipo.entrega,
      'entrega' => TimelineTipo.entrega,
      _ => TimelineTipo.estudio,
    };
    final tieneTemas = h.temas != null && h.temas!.isNotEmpty;
    final titulo = switch (tipo) {
      TimelineTipo.clase => tieneTemas ? h.temas! : 'Clase',
      TimelineTipo.deporte => tieneTemas ? h.temas! : 'Entrenamiento',
      TimelineTipo.entrega => tieneTemas ? h.temas! : 'Tarea académica',
      _ => tieneTemas ? h.temas! : 'Estudio',
    };
    return TimelineItem(
      id: h.id,
      tipo: tipo,
      titulo: titulo,
      subtitulo: h.ubicacion ?? '',
      horaInicio: h.horaInicio,
      horaFin: h.horaFin,
      completado: h.completado,
      datosOriginales: h,
      duracionMinutos: h.horaFin.difference(h.horaInicio).inMinutes,
      rutinaId: h.rutinaId,
    );
  }

  factory TimelineItem.desdeSesion(SesionRegistradaDb s) {
    return TimelineItem(
      id: s.id,
      tipo: TimelineTipo.deporte,
      titulo: 'Entrenamiento',
      subtitulo: '${s.duracionMinutos} min · RPE ${s.rpe}',
      horaInicio: s.completadaEn,
      horaFin: s.completadaEn,
      completado: true,
      datosOriginales: s,
      duracionMinutos: s.duracionMinutos,
      rpe: s.rpe,
      rutinaId: s.rutinaId,
    );
  }

  factory TimelineItem.desdeEntrega(EntregaExamenDb e) {
    final ahora = DateTime.now();
    final diff = e.fechaLimite.difference(
      DateTime(ahora.year, ahora.month, ahora.day),
    );
    final dias = diff.inDays;
    return TimelineItem(
      id: e.id,
      tipo: TimelineTipo.entrega,
      titulo: e.titulo,
      subtitulo: dias > 0
          ? 'Vence en $dias dias'
          : dias == 0
              ? 'Vence hoy'
              : 'Vencido',
      horaInicio: e.fechaLimite,
      horaFin: e.fechaLimite,
      completado: e.estaCompletado,
      datosOriginales: e,
      diasRestantes: dias,
    );
  }

  factory TimelineItem.desdeReto(RetoDb r) {
    final dias = r.fechaFin.difference(DateTime.now()).inDays;
    return TimelineItem(
      id: r.id,
      tipo: TimelineTipo.reto,
      titulo: r.titulo,
      subtitulo: dias > 0 ? 'Quedan $dias dias' : 'Finaliza hoy',
      horaInicio: r.fechaInicio,
      horaFin: r.fechaFin,
      completado: r.estaCompletado,
      datosOriginales: r,
      diasRestantes: dias,
    );
  }

  factory TimelineItem.desdeHito(HitoRetoDb h, RetoDb reto) {
    return TimelineItem(
      id: h.id,
      tipo: TimelineTipo.hitoReto,
      titulo: h.titulo,
      subtitulo: 'Reto: ${reto.titulo}',
      horaInicio: reto.fechaFin,
      horaFin: reto.fechaFin,
      completado: h.estaCompletado,
      datosOriginales: {'hito': h, 'reto': reto},
      diasRestantes: reto.fechaFin.difference(DateTime.now()).inDays,
    );
  }

  factory TimelineItem.desdeDiaPendiente(Map<String, String> d) {
    final ahora = DateTime.now();
    return TimelineItem(
      id: d['diaId'] ?? '',
      tipo: TimelineTipo.entrenamientoPendiente,
      titulo: 'Entrenamiento pendiente',
      subtitulo: 'Toca entrenar hoy',
      horaInicio: ahora,
      horaFin: ahora,
      completado: false,
      rutinaId: d['rutinaId'],
    );
  }
}
