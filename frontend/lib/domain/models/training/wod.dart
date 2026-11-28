import 'package:freezed_annotation/freezed_annotation.dart';

part 'wod.freezed.dart';

/// Formato de un WOD (ADR 0069), con los códigos del servidor.
enum WodFormat {
  forTime('FOR_TIME'),
  amrap('AMRAP'),
  emom('EMOM'),
  tabata('TABATA');

  const WodFormat(this.api);

  final String api;

  static WodFormat fromApi(String? value) =>
      values.where((f) => f.api == value).firstOrNull ?? forTime;

  /// Qué se apunta en cada formato, para saber qué campos pide la hoja de la
  /// marca. El servidor lo decide igual y rechaza lo que no cuadre.
  WodScoreType scoreType({required bool capped}) => switch (this) {
    WodFormat.forTime => capped ? WodScoreType.reps : WodScoreType.time,
    WodFormat.amrap => WodScoreType.roundsReps,
    WodFormat.emom || WodFormat.tabata => WodScoreType.reps,
  };
}

/// En qué se cuenta un movimiento.
enum WodUnit {
  reps('REPS'),
  calories('CALORIES'),
  meters('METERS');

  const WodUnit(this.api);

  final String api;

  static WodUnit fromApi(String? value) =>
      values.where((u) => u.api == value).firstOrNull ?? reps;
}

/// Tal cual está escrito (Rx) o adaptado.
enum WodDivision {
  rx('RX'),
  scaled('SCALED');

  const WodDivision(this.api);

  final String api;

  static WodDivision fromApi(String? value) =>
      values.where((d) => d.api == value).firstOrNull ?? rx;
}

/// Qué mide una marca.
enum WodScoreType {
  time('TIME'),
  roundsReps('ROUNDS_REPS'),
  reps('REPS'),
  load('LOAD');

  const WodScoreType(this.api);

  final String api;

  static WodScoreType fromApi(String? value) =>
      values.where((t) => t.api == value).firstOrNull ?? reps;
}

/// Un movimiento de la pizarra. [code] es el de una plantilla de ejemplo (la
/// pantalla lo nombra en cada idioma); [name], el que escribió la persona.
/// [quantity] nula = «las que puedas».
@freezed
abstract class WodMovement with _$WodMovement {
  const factory WodMovement({
    String? code,
    String? name,
    int? quantity,
    @Default(WodUnit.reps) WodUnit unit,
    double? rxKg,
    double? scaledKg,
  }) = _WodMovement;
}

/// La pizarra de un WOD: mío ([id]) o una plantilla de ejemplo
/// ([templateCode] sin [id]). Las reglas de cada formato las aplica el
/// servidor.
@freezed
abstract class Wod with _$Wod {
  const factory Wod({
    String? id,
    String? templateCode,
    String? title,
    String? strength,
    required WodFormat format,
    int? timeCapSeconds,
    int? rounds,
    required List<WodMovement> movements,
  }) = _Wod;
}

/// Una marca guardada. [value]: segundos, rondas (con [extraReps]),
/// repeticiones o kilos, según [scoreType].
@freezed
abstract class WodResult with _$WodResult {
  const factory WodResult({
    required String id,
    required String wodId,
    required WodDivision division,
    required WodScoreType scoreType,
    required int value,
    int? extraReps,
    @Default(false) bool capped,
    @Default(0) int durationSeconds,
    required DateTime performedAt,
  }) = _WodResult;
}

/// La pizarra de hoy con sus marcas. [example]: es una plantilla de ejemplo,
/// no un WOD de la persona. La mejor marca la calcula el servidor.
@freezed
abstract class WodBoard with _$WodBoard {
  const factory WodBoard({
    required Wod wod,
    @Default(false) bool example,
    WodResult? bestRx,
    WodResult? bestScaled,
    WodResult? todayResult,
  }) = _WodBoard;

  const WodBoard._();

  WodResult? best(WodDivision division) =>
      division == WodDivision.rx ? bestRx : bestScaled;
}

/// Una marca de «Mis marcas» con su WOD. [best]: la mejor de ese WOD en su
/// división (lo dice el servidor).
@freezed
abstract class WodMark with _$WodMark {
  const factory WodMark({
    required WodResult result,
    String? title,
    String? templateCode,
    required WodFormat format,
    @Default(false) bool best,
  }) = _WodMark;
}

/// Lo que se apunta al guardar una marca. [durationSeconds]: lo que marcó el
/// cronómetro (nulo si se apunta sin él).
@freezed
abstract class WodResultDraft with _$WodResultDraft {
  const factory WodResultDraft({
    required WodDivision division,
    required int value,
    int? extraReps,
    @Default(false) bool capped,
    int? durationSeconds,
  }) = _WodResultDraft;
}
