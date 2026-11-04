import 'package:freezed_annotation/freezed_annotation.dart';

part 'sport_activity.freezed.dart';

/// Clase de deporte apuntado a mano.
enum ActivityKind {
  run('RUN', measuresDistance: true),
  walk('WALK', measuresDistance: true),
  bike('BIKE', measuresDistance: true),
  swim('SWIM', measuresDistance: true),
  match('MATCH'),
  other('OTHER');

  const ActivityKind(this.api, {this.measuresDistance = false});

  final String api;

  /// Correr, andar, bici y nadar se apuntan con distancia (lo valida también
  /// el servidor).
  final bool measuresDistance;

  static ActivityKind? fromApi(String? value) =>
      values.where((k) => k.api == value).firstOrNull;
}

/// Deporte hecho fuera de las rutinas (un partido o una actividad apuntada):
/// ritmo y velocidad los calcula el servidor.
@freezed
abstract class SportActivity with _$SportActivity {
  const factory SportActivity({
    required String blockId,
    required DateTime start,
    required int minutes,
    String? title,
    ActivityKind? kind,
    int? distanceMeters,
    int? effort,
    int? paceSecondsPerKm,
    double? speedKmh,
  }) = _SportActivity;
}
