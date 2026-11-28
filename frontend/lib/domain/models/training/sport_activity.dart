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

/// Familia de un deporte del catálogo: decide qué se pregunta al apuntarlo.
enum SportCategory { endurance, match, other }

/// Catálogo de deportes (ADR 0068), con los códigos del servidor. Cada uno
/// conserva su [ActivityKind] de antes, que es lo que decide si lleva
/// distancia.
enum Sport {
  run('RUN', SportCategory.endurance, ActivityKind.run),
  walk('WALK', SportCategory.endurance, ActivityKind.walk),
  bike('BIKE', SportCategory.endurance, ActivityKind.bike),
  swim('SWIM', SportCategory.endurance, ActivityKind.swim),
  football('FOOTBALL', SportCategory.match, ActivityKind.match),
  padel('PADEL', SportCategory.match, ActivityKind.match),
  basketball('BASKETBALL', SportCategory.match, ActivityKind.match),
  volleyball('VOLLEYBALL', SportCategory.match, ActivityKind.match),
  tennis('TENNIS', SportCategory.match, ActivityKind.match),
  other('OTHER', SportCategory.other, ActivityKind.other);

  const Sport(this.api, this.category, this.kind);

  final String api;
  final SportCategory category;
  final ActivityKind kind;

  /// Los que se graban con el GPS de la app.
  bool get recordsWithGps =>
      this == Sport.run || this == Sport.walk || this == Sport.bike;

  static Sport? fromApi(String? value) =>
      values.where((s) => s.api == value).firstOrNull;
}

/// Qué fue una actividad de un deporte de partido.
enum SportMode {
  match('MATCH'),
  training('TRAINING');

  const SportMode(this.api);

  final String api;

  static SportMode? fromApi(String? value) =>
      values.where((m) => m.api == value).firstOrNull;
}

/// Resultado de un partido; opcional y solo informativo.
enum MatchResult {
  win('WIN'),
  draw('DRAW'),
  loss('LOSS');

  const MatchResult(this.api);

  final String api;

  static MatchResult? fromApi(String? value) =>
      values.where((r) => r.api == value).firstOrNull;
}

/// Qué deporte fue una actividad y, si es de partido, cómo fue (ADR 0068).
/// Qué campos valen en cada deporte lo decide el servidor: un entreno no
/// guarda resultado y solo «otro deporte» guarda [name].
@freezed
abstract class SportEntry with _$SportEntry {
  const factory SportEntry({
    required Sport sport,

    /// Nombre libre de «otro deporte» («Escalada»).
    String? name,
    SportMode? mode,
    MatchResult? result,

    /// Marcador tal como se escribió («6-4 6-3»).
    String? scoreText,
  }) = _SportEntry;

  /// Letras que admite el marcador (lo valida el servidor).
  static const scoreMax = 20;

  /// Letras que guarda el servidor del nombre de «otro deporte».
  static const nameMax = 40;
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

    /// Deporte y datos de partido; nulo si se marcó en el calendario.
    SportEntry? sport,
  }) = _SportActivity;

  /// Minutos (en movimiento, si es con GPS) para que algo cuente como
  /// actividad. Lo decide el servidor (`RUN_TOO_SHORT` y la validación de
  /// «Apuntar actividad»); el móvil solo lo usa para avisar antes.
  static const minMinutes = 10;
}
