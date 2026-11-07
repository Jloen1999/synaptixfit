import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/training/run.dart';

/// Carreras con GPS y entrenos de carrera en el servidor (ADR 0037).
abstract interface class RunRepositoryContract {
  /// Sube una carrera terminada (idempotente con su `clientKey`).
  Future<AppResult<RunSaved>> upload(RunRecording recording);

  Future<AppResult<RunDetail>> getRun(String blockId);

  Future<AppResult<Unit>> deleteRun(String blockId);

  Future<AppResult<RunWeek>> getWeek();

  Future<AppResult<List<RunWorkout>>> listWorkouts();

  /// Plantillas: solo código y pasos; el nombre lo pone la pantalla.
  Future<AppResult<List<RunWorkout>>> listTemplates();

  Future<AppResult<RunWorkout>> createWorkout(RunWorkout workout);

  Future<AppResult<RunWorkout>> updateWorkout(RunWorkout workout);

  Future<AppResult<Unit>> deleteWorkout(String workoutId);

  /// «Poner en el calendario»: devuelve el id del evento creado.
  Future<AppResult<String>> scheduleWorkout(String workoutId, DateTime start);

  Future<AppResult<List<PlannedRun>>> listPlanned();
}

/// Carrera en curso y cola de carreras por subir, en el teléfono.
abstract interface class RunRecordingRepositoryContract {
  Future<AppResult<RunRecording?>> loadCurrent();

  /// Guarda la carrera en curso; `null` la olvida.
  Future<AppResult<Unit>> saveCurrent(RunRecording? recording);

  Future<AppResult<List<RunRecording>>> pending();

  Future<AppResult<Unit>> addPending(RunRecording recording);

  Future<AppResult<Unit>> removePending(String clientKey);
}

/// GPS del móvil. En Android sigue con la pantalla apagada mediante un
/// servicio en primer plano con su aviso fijo.
abstract interface class RunTrackerRepositoryContract {
  /// Si esta plataforma graba con GPS (Android e iOS; no web ni escritorio).
  bool get supported;

  Future<AppResult<bool>> locationServiceEnabled();

  /// Posición actual para «Estás aquí» (nula si no se puede).
  Future<AppResult<RunFix?>> currentPosition();

  /// Puntos mientras dure la suscripción; el aviso fijo arranca con
  /// [notificationTitle] y [notificationText].
  Stream<AppResult<RunFix>> watch({
    required String notificationTitle,
    required String notificationText,
    required String channelName,
  });

  /// Cambia el texto del aviso fijo («Grabando tu carrera · 3,2 km · 18:40»).
  Future<void> updateNotification({
    required String title,
    required String text,
    required String channelName,
  });

  /// Vibración corta al cambiar de paso.
  Future<void> vibrate();
}
