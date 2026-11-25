import '../../enums/item_time_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/planner_enums.dart';

part 'calendar_block.freezed.dart';

/// Bloque del calendario semanal. Las fechas están en hora local.
@freezed
abstract class CalendarBlock with _$CalendarBlock {
  const factory CalendarBlock({
    required String id,
    required BlockType type,
    required DateTime start,
    required DateTime end,
    String? subjectId,
    String? topics,
    String? location,
    PlannerPriority? priority,
    @Default(false) bool privateBlock,
    ClassKind? classKind,
    @Default(false) bool fixed,
    @Default(false) bool immovable,
    @Default(false) bool imported,
    @Default(false) bool hasConflict,
    @Default(false) bool completed,
    @Default(0) int xpReward,
    String? routineId,
    String? routineWeekId,
    String? routineDayId,
    String? challengeId,
    String? milestoneId,
    String? deadlineId,

    /// Pendiente, en curso, hecho o no hecho (lo decide el servidor).
    @Default(ItemTimeStatus.upcoming) ItemTimeStatus timeStatus,

    /// Deporte que no es una sesión de rutina: al marcarlo hecho se pide el
    /// esfuerzo para su carga física (lo decide el servidor).
    @Default(false) bool tracksPhysicalLoad,

    /// Clase marcada «No fui»: no se da por asistida sola al terminar
    /// (ADR 0029; lo decide el servidor).
    @Default(false) bool absent,
  }) = _CalendarBlock;

  const CalendarBlock._();

  /// Fijo o inamovible: no se puede mover ni redimensionar.
  bool get isLocked => fixed || immovable;

  Duration get duration => end.difference(start);

  /// Enlace `https` de una clase en línea escrito en «Lugar» (Teams, Meet,
  /// Zoom…), sin la puntuación que lo cierra en la frase («(https://…).»);
  /// nulo si es un aula u otro texto. Solo `https`, como el resto de enlaces.
  Uri? get onlineLink => _linkMatch?.$1;

  /// «Lugar» con el enlace cambiado por su dominio («teams.microsoft.com»):
  /// la dirección entera no se entiende leída ni dicha en voz alta.
  String? get locationShown {
    final text = location?.trim();
    final match = _linkMatch;
    if (text == null || match == null) return text;
    return text.replaceFirst(match.$2, match.$1.host);
  }

  static final _link = RegExp(r'https://\S+');
  static final _closing = RegExp(r'[.,;:)\]>]+$');

  (Uri, String)? get _linkMatch {
    final found = _link.firstMatch(location ?? '')?.group(0);
    if (found == null) return null;
    final raw = found.replaceFirst(_closing, '');
    final uri = Uri.tryParse(raw);
    return uri != null && uri.host.isNotEmpty ? (uri, raw) : null;
  }
}

/// Bloque creado o movido junto con los bloques con los que se solapa.
@freezed
abstract class BlockChange with _$BlockChange {
  const factory BlockChange({
    required CalendarBlock block,
    @Default(<CalendarBlock>[]) List<CalendarBlock> conflicts,

    /// Copias creadas con «Repetir cada semana».
    @Default(0) int weeklyCopies,
  }) = _BlockChange;
}

/// Bloque tras marcar/desmarcar y experiencia sumada (o restada si es negativa).
@freezed
abstract class BlockCompletion with _$BlockCompletion {
  const factory BlockCompletion({
    required CalendarBlock block,
    required int xpDelta,
  }) = _BlockCompletion;
}

/// Pareja de bloques que ocupan la misma hora (choque de horario).
@freezed
abstract class BlockConflict with _$BlockConflict {
  const BlockConflict._();

  const factory BlockConflict({
    required CalendarBlock first,
    required CalendarBlock second,
  }) = _BlockConflict;

  /// Desde cuándo coinciden: el inicio más tardío de los dos.
  DateTime get overlapStart =>
      first.start.isAfter(second.start) ? first.start : second.start;

  /// Hasta cuándo coinciden: el final más temprano de los dos.
  DateTime get overlapEnd =>
      first.end.isBefore(second.end) ? first.end : second.end;
}
