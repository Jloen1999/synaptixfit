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

/// De dónde sale una actividad (ADR 0037): «Apuntada a mano» o «GPS de la
/// app». Nulo si se marcó como hecho un evento del calendario.
enum ActivitySource {
  manual('MANUAL'),
  gps('GPS');

  const ActivitySource(this.api);

  final String api;

  static ActivitySource? fromApi(String? value) =>
      values.where((s) => s.api == value).firstOrNull;
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

    /// Ritmo por 100 m (natación); lo calcula el servidor.
    int? paceSecondsPer100m,
    double? speedKmh,
    ActivitySource? source,

    /// Desnivel positivo de una carrera grabada con GPS.
    int? elevationGainMeters,
  }) = _SportActivity;

  /// Minutos (en movimiento, si es con GPS) para que algo cuente como
  /// actividad. Lo decide el servidor (`RUN_TOO_SHORT` y la validación de
  /// «Apuntar actividad»); el móvil solo lo usa para avisar antes.
  static const minMinutes = 10;
}
