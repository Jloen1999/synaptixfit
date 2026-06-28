import 'package:flutter/material.dart';

import '../domain/calendar_dtos.dart';

/// Constantes de diseño del grid de time-blocking semanal.
class GridConstants {
  GridConstants._();

  /// Píxeles por hora en el eje Y.
  static const double pixelsPerHour = 80.0;

  /// Hora de inicio visible del grid (6:00 AM).
  static const int hourStart = 6;

  /// Hora de fin visible del grid (23:00 / 11 PM).
  static const int hourEnd = 23;

  /// Altura total del grid en píxeles.
  static const double totalGridHeight = 1360.0;

  /// Ancho de cada columna de día.
  static const double columnWidth = 120.0;

  /// Ancho de la columna de etiquetas de hora (0 = inline en el painter).
  static const double hourColumnWidth = 0.0;

  /// Altura del header con nombres de días.
  static const double headerHeight = 40.0;

  /// Altura total del canvas (header + grid).
  static const double totalCanvasHeight = headerHeight + totalGridHeight;

  /// Ancho total del canvas (7 columnas días, sin columna de horas).
  static const double totalCanvasWidth = 7 * columnWidth;

  /// Snap de redimensionamiento: media hora en píxeles.
  static const double snapHalfHour = pixelsPerHour / 2;

  /// Nombres cortos de días.
  static const List<String> dayNames = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  /// Nombres completos de días.
  static const List<String> dayNamesFull = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
}

/// Funciones de conversión hora ↔ píxel para el grid semanal.
class GridMath {
  GridMath._();

  // ---------------------------------------------------------------------------
  // Conversiones de hora ↔ offset Y
  // ---------------------------------------------------------------------------

  /// Convierte [hora] a posición Y en píxeles dentro del grid.
  /// El offset 0 corresponde a las 07:00.
  static double horaToOffsetY(TimeOfDay hora) {
    final totalMinutes = hora.hour * 60 + hora.minute;
    const gridStartMinutes = GridConstants.hourStart * 60;
    final relativeMinutes = totalMinutes - gridStartMinutes;
    if (relativeMinutes < 0) return 0.0;
    return relativeMinutes / 60.0 * GridConstants.pixelsPerHour;
  }

  /// Convierte duración (inicio → fin) a altura en píxeles.
  static double duracionToHeight(TimeOfDay inicio, TimeOfDay fin) {
    final inicioMin = inicio.hour * 60 + inicio.minute;
    final finMin = fin.hour * 60 + fin.minute;
    if (finMin <= inicioMin) return 0.0;
    final duracionMin = finMin - inicioMin;
    return duracionMin / 60.0 * GridConstants.pixelsPerHour;
  }

  /// Convierte [offsetY] (píxeles desde el top del grid) a TimeOfDay.
  /// Incluye snap a la media hora más cercana.
  static TimeOfDay offsetYToHora(double offsetY) {
    final relativeMinutes = (offsetY / GridConstants.pixelsPerHour) * 60.0;
    final totalMinutes = GridConstants.hourStart * 60 + relativeMinutes;

    final snappedMinutes = (totalMinutes / 30).round() * 30;
    final clampedMinutes = snappedMinutes.clamp(0, 23 * 60 + 59);

    final hour = clampedMinutes ~/ 60;
    final minute = clampedMinutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // ---------------------------------------------------------------------------
  // Conversiones de offset X ↔ día
  // ---------------------------------------------------------------------------

  /// Convierte [offsetX] a día de la semana (1-7). Retorna -1 si está fuera.
  static int offsetXToDia(double offsetX) {
    final xEnGrid = offsetX - GridConstants.hourColumnWidth;
    if (xEnGrid < 0) return -1;
    final dia = (xEnGrid / GridConstants.columnWidth).floor() + 1;
    return (dia >= 1 && dia <= 7) ? dia : -1;
  }

  /// Convierte [diaSemana] (1-7) a offset X del borde izquierdo de su columna.
  static double diaToOffsetX(int diaSemana) {
    return GridConstants.hourColumnWidth +
        ((diaSemana - 1) * GridConstants.columnWidth);
  }

  // ---------------------------------------------------------------------------
  // Conversiones basadas en fecha absoluta (Lienzo Continuo)
  // ---------------------------------------------------------------------------

  static int fechaToColumnIndex(DateTime fecha, DateTime fechaBase) {
    final base = DateTime(fechaBase.year, fechaBase.month, fechaBase.day);
    final target = DateTime(fecha.year, fecha.month, fecha.day);
    return target.difference(base).inDays;
  }

  static DateTime columnIndexToFecha(int columna, DateTime fechaBase) {
    final base = DateTime(fechaBase.year, fechaBase.month, fechaBase.day);
    return base.add(Duration(days: columna));
  }

  static double fechaToOffsetX(DateTime fecha, DateTime fechaBase) {
    final col = fechaToColumnIndex(fecha, fechaBase);
    return GridConstants.hourColumnWidth + (col * GridConstants.columnWidth);
  }

  static int offsetXToColumnIndex(double offsetX) {
    final xEnGrid = offsetX - GridConstants.hourColumnWidth;
    if (xEnGrid < 0) return -1;
    final col = (xEnGrid / GridConstants.columnWidth).floor();
    return (col >= 0 && col < 7) ? col : -1;
  }

  static String dayHeaderLabel(DateTime fecha) {
    final nombres = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${nombres[fecha.weekday - 1]} ${fecha.day}';
  }

  // ---------------------------------------------------------------------------
  // Detección de solapamiento
  // ---------------------------------------------------------------------------

  /// Verifica si dos bloques se solapan en el mismo día.
  static bool seSolapan(TimeBlock a, TimeBlock b) {
    if (a.diaSemana != b.diaSemana) return false;
    final aInicio = a.horaInicio.hour * 60 + a.horaInicio.minute;
    final aFin = a.horaFin.hour * 60 + a.horaFin.minute;
    final bInicio = b.horaInicio.hour * 60 + b.horaInicio.minute;
    final bFin = b.horaFin.hour * 60 + b.horaFin.minute;
    return aInicio < bFin && bInicio < aFin;
  }

  /// Encuentra todos los bloques que se solapan con [bloque].
  static List<TimeBlock> encontrarSolapamientos(
    TimeBlock bloque,
    List<TimeBlock> todos, {
    String? ignorarId,
  }) {
    return todos.where((b) {
      if (b.idLocal == ignorarId) return false;
      return seSolapan(bloque, b);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Validaciones de constraints
  // ---------------------------------------------------------------------------

  /// Valida que un bloque cumpla las reglas del sistema.
  static List<ConflictInfo> validarConstraints(
    TimeBlock bloque,
    List<TimeBlock> existentes, {
    String? ignorarId,
  }) {
    final conflictos = <ConflictInfo>[];

    for (final b in existentes) {
      if (b.idLocal == ignorarId) continue;
      if (b.esFijo && seSolapan(bloque, b)) {
        conflictos.add(ConflictInfo(
          bloqueIdA: bloque.idLocal,
          bloqueIdB: b.idLocal,
          descripcion:
              'Solapamiento con bloque fijo: ${b.titulo ?? b.tipo.name}',
          severidad: ConflictSeverity.error,
        ));
      }
    }

    for (final b in existentes) {
      if (b.idLocal == ignorarId) continue;
      if (!b.esFijo && seSolapan(bloque, b)) {
        conflictos.add(ConflictInfo(
          bloqueIdA: bloque.idLocal,
          bloqueIdB: b.idLocal,
          descripcion: 'Solapamiento con: ${b.titulo ?? b.tipo.name}',
          severidad: ConflictSeverity.warning,
        ));
      }
    }

    final duracionMin = bloque.duracion.inMinutes;
    if (duracionMin < 30) {
      conflictos.add(const ConflictInfo(
        bloqueIdA: '',
        bloqueIdB: '',
        descripcion: 'La duración mínima es 30 minutos',
        severidad: ConflictSeverity.error,
      ));
    }
    if (duracionMin > 240) {
      conflictos.add(const ConflictInfo(
        bloqueIdA: '',
        bloqueIdB: '',
        descripcion: 'La duración máxima es 4 horas',
        severidad: ConflictSeverity.warning,
      ));
    }

    final inicioMin = bloque.horaInicio.hour * 60 + bloque.horaInicio.minute;
    final finMin = bloque.horaFin.hour * 60 + bloque.horaFin.minute;
    if (inicioMin < GridConstants.hourStart * 60 ||
        finMin > GridConstants.hourEnd * 60) {
      conflictos.add(const ConflictInfo(
        bloqueIdA: '',
        bloqueIdB: '',
        descripcion: 'El bloque está fuera del rango visible (07:00-23:00)',
        severidad: ConflictSeverity.warning,
      ));
    }

    return conflictos;
  }

  // ---------------------------------------------------------------------------
  // Utilidades de formato
  // ---------------------------------------------------------------------------

  /// Formatea TimeOfDay a "HH:mm".
  static String formatTimeOfDay(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// Parsea "HH:mm" a TimeOfDay.
  static TimeOfDay parseTimeOfDay(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
