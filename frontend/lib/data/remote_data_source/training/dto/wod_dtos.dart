import '../../../../domain/models/training/wod.dart';

/// JSON de los WOD (`/training/wods`, ADR 0069).
abstract final class WodDtos {
  static WodMovement movement(Map<String, dynamic> json) => WodMovement(
    code: json['code'] as String?,
    name: json['name'] as String?,
    quantity: json['quantity'] as int?,
    unit: WodUnit.fromApi(json['unit'] as String?),
    rxKg: (json['rxKg'] as num?)?.toDouble(),
    scaledKg: (json['scaledKg'] as num?)?.toDouble(),
  );

  /// Vale para un WOD mío, una plantilla (`code`) y la pizarra (`wodId`).
  static Wod wod(Map<String, dynamic> json) => Wod(
    id: (json['id'] ?? json['wodId']) as String?,
    templateCode: (json['templateCode'] ?? json['code']) as String?,
    title: json['title'] as String?,
    strength: json['strength'] as String?,
    format: WodFormat.fromApi(json['format'] as String?),
    timeCapSeconds: json['timeCapSeconds'] as int?,
    rounds: json['rounds'] as int?,
    movements: [
      for (final m in json['movements'] as List<dynamic>? ?? const [])
        movement(m as Map<String, dynamic>),
    ],
  );

  static Map<String, dynamic> wodBody(Wod w) => {
    'templateCode': ?w.templateCode,
    'title': ?w.title,
    'strength': ?w.strength,
    'format': w.format.api,
    'timeCapSeconds': ?w.timeCapSeconds,
    'rounds': ?w.rounds,
    'movements': [
      for (final m in w.movements)
        {
          'code': ?m.code,
          'name': ?m.name,
          'quantity': ?m.quantity,
          'unit': m.unit.api,
          'rxKg': ?m.rxKg,
          'scaledKg': ?m.scaledKg,
        },
    ],
  };

  static WodResult? result(Map<String, dynamic>? json) => json == null
      ? null
      : WodResult(
          id: json['id'] as String,
          wodId: json['wodId'] as String,
          division: WodDivision.fromApi(json['division'] as String?),
          scoreType: WodScoreType.fromApi(json['scoreType'] as String?),
          value: json['value'] as int? ?? 0,
          extraReps: json['extraReps'] as int?,
          capped: json['capped'] as bool? ?? false,
          durationSeconds: json['durationSeconds'] as int? ?? 0,
          performedAt: DateTime.parse(json['performedAt'] as String).toLocal(),
        );

  static WodBoard board(Map<String, dynamic> json) => WodBoard(
    wod: wod(json),
    example: json['example'] as bool? ?? false,
    bestRx: result(json['bestRx'] as Map<String, dynamic>?),
    bestScaled: result(json['bestScaled'] as Map<String, dynamic>?),
    todayResult: result(json['todayResult'] as Map<String, dynamic>?),
  );

  static WodMark mark(Map<String, dynamic> json) => WodMark(
    result: result(json['result'] as Map<String, dynamic>)!,
    title: json['title'] as String?,
    templateCode: json['templateCode'] as String?,
    format: WodFormat.fromApi(json['format'] as String?),
    best: json['best'] as bool? ?? false,
  );

  /// Con un WOD mío basta su id; una plantilla aún sin usar viaja entera y el
  /// servidor crea mi WOD con ella.
  static Map<String, dynamic> resultBody(Wod w, WodResultDraft d) => {
    if (w.id case final id?) 'wodId': id else 'wod': wodBody(w),
    'division': d.division.api,
    'value': d.value,
    'extraReps': ?d.extraReps,
    'capped': d.capped,
    'durationSeconds': ?d.durationSeconds,
  };
}
