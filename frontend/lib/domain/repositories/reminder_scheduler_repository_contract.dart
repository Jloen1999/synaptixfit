import '../models/reminders/ongoing_timer.dart';
import '../models/reminders/reminder.dart';
import '../models/reminders/timer_alert.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Puerto hacia las notificaciones locales del dispositivo. En móvil lo
/// implementa el plugin de notificaciones; en web, una versión que no hace nada.
abstract interface class ReminderSchedulerRepositoryContract {
  /// `false` donde no hay avisos locales (web).
  bool get isSupported;

  /// Pide permiso al sistema; devuelve si se concedió. Si el sistema ya no
  /// muestra el diálogo (se negó antes), devuelve el estado actual.
  Future<AppResult<bool>> requestPermission();

  /// Si el sistema permite ahora mostrar avisos de la app (sin preguntar).
  Future<AppResult<bool>> hasPermission();

  /// Sustituye todos los avisos pendientes por [reminders].
  Future<AppResult<Unit>> replaceAll(
    List<Reminder> reminders, {
    required String channelName,
  });

  /// Quita los avisos pendientes y los ya mostrados.
  Future<AppResult<Unit>> cancelAll();

  /// Aviso de fin de fase del Pomodoro: uno solo, aparte de los recordatorios
  /// (sustituirlos no lo quita).
  Future<AppResult<Unit>> scheduleTimerAlert(TimerAlert alert);

  Future<AppResult<Unit>> cancelTimerAlert();

  /// Notificación fija del Pomodoro en marcha (cuenta atrás en la barra).
  Future<AppResult<Unit>> showOngoingTimer(OngoingTimer timer);

  Future<AppResult<Unit>> cancelOngoingTimer();

  /// Avisos que el usuario toca (también el que abrió la app en frío).
  Stream<OpenedReminder> watchOpened();
}
