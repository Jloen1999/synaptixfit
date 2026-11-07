import '../../../../domain/models/training/run.dart';
import '../../../../domain/models/training/sport_activity.dart';

/// JSON de las carreras con GPS y los entrenos de carrera (`/training/runs`,
/// `/training/run-workouts`). La ruta viaja compacta: un array por punto
/// `[lat, lon, altitud|null, precisión, segundos, segmento]`.
abstract final class RunDtos {
  static Map<String, dynamic> recordingBody(RunRecording r) => {
    'clientKey': r.clientKey,
    'kind': r.kind.api,
    'startedAt': r.startedAt.toUtc().toIso8601String(),
    'effort': r.effort,
    'points': [
      for (final p in r.points)
        [
          p.latitude,
          p.longitude,
          p.altitude,
          p.accuracy,
          p.offsetSeconds,
          p.segment.toDouble(),
        ],
    ],
    'workoutId': ?r.workoutId,
    'plannedBlockId': ?r.plannedBlockId,
  };

  static RunSaved saved(Map<String, dynamic> json) => RunSaved(
    run: detail(json['run'] as Map<String, dynamic>),
    xpDelta: json['xpDelta'] as int? ?? 0,
  );

  static RunDetail detail(Map<String, dynamic> json) => RunDetail(
    blockId: json['blockId'] as String,
    kind: ActivityKind.fromApi(json['kind'] as String?) ?? ActivityKind.run,
    title: json['title'] as String?,
    startedAt: DateTime.parse(json['startedAt'] as String).toLocal(),
    endedAt: DateTime.parse(json['endedAt'] as String).toLocal(),
    distanceMeters: json['distanceMeters'] as int? ?? 0,
    movingSeconds: json['movingSeconds'] as int? ?? 0,
    paceSecondsPerKm: json['paceSecondsPerKm'] as int?,
    elevationGainMeters: json['elevationGainMeters'] as int? ?? 0,
    kcal: json['kcal'] as int?,
    effort: json['effort'] as int? ?? 0,
    splits: [
      for (final s in (json['splits'] as List<dynamic>? ?? const []))
        RunSplit(
          number: (s as Map<String, dynamic>)['number'] as int,
          distanceMeters: s['distanceMeters'] as int,
          seconds: s['seconds'] as int,
          paceSecondsPerKm: s['paceSecondsPerKm'] as int,
        ),
    ],
    route: [
      for (final p in (json['route'] as List<dynamic>? ?? const []))
        (((p as List<dynamic>)[0] as num).toDouble(), (p[1] as num).toDouble()),
    ],
    workoutId: json['workoutId'] as String?,
  );

  static RunWeek week(Map<String, dynamic> json) => RunWeek(
    weekStart: DateTime.parse(json['weekStart'] as String),
    distanceMeters: json['distanceMeters'] as int? ?? 0,
    movingSeconds: json['movingSeconds'] as int? ?? 0,
    elevationGainMeters: json['elevationGainMeters'] as int? ?? 0,
    outings: json['outings'] as int? ?? 0,
    dailyDistanceMeters: [
      for (final d
          in (json['dailyDistanceMeters'] as List<dynamic>? ?? const []))
        (d as num).toInt(),
    ],
  );

  static List<RunStepGroup> _groups(List<dynamic>? json) => [
    for (final g in json ?? const [])
      RunStepGroup(
        repeat: (g as Map<String, dynamic>)['repeat'] as int? ?? 1,
        steps: [
          for (final s in (g['steps'] as List<dynamic>? ?? const []))
            RunStep(
              type: RunStepType.fromApi(
                (s as Map<String, dynamic>)['type'] as String?,
              ),
              measure: RunMeasure.fromApi(s['measure'] as String?),
              value: s['value'] as int? ?? 0,
            ),
        ],
      ),
  ];

  static RunWorkout workout(Map<String, dynamic> json) => RunWorkout(
    id: json['id'] as String?,
    name: json['name'] as String? ?? '',
    templateCode: json['templateCode'] as String?,
    groups: _groups(json['groups'] as List<dynamic>?),
    estimatedSeconds: json['estimatedSeconds'] as int? ?? 0,
  );

  static RunWorkout template(Map<String, dynamic> json) => RunWorkout(
    name: '',
    templateCode: json['code'] as String?,
    groups: _groups(json['groups'] as List<dynamic>?),
  );

  static Map<String, dynamic> workoutBody(RunWorkout w) => {
    'name': w.name,
    'templateCode': ?w.templateCode,
    'groups': [
      for (final g in w.groups)
        {
          'repeat': g.repeat,
          'steps': [
            for (final s in g.steps)
              {'type': s.type.api, 'measure': s.measure.api, 'value': s.value},
          ],
        },
    ],
  };

  static PlannedRun planned(Map<String, dynamic> json) => PlannedRun(
    blockId: json['blockId'] as String,
    workoutId: json['workoutId'] as String,
    workoutName: json['workoutName'] as String? ?? '',
    start: DateTime.parse(json['start'] as String).toLocal(),
    end: DateTime.parse(json['end'] as String).toLocal(),
  );
}
