import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/reminders/ongoing_timer.dart';
import '../../domain/models/reminders/reminder.dart';
import '../../domain/models/reminders/timer_alert.dart';

/// Acceso técnico a las notificaciones locales del sistema. Lo usa
/// `ReminderSchedulerRepository`; puede lanzar excepciones del plugin.
abstract interface class LocalReminderScheduler {
  bool get isSupported;

  Future<bool> requestPermission();

  Future<bool> hasPermission();

  Future<void> replaceAll(List<Reminder> reminders, String channelName);

  Future<void> cancelAll();

  /// Aviso de fin de fase del Pomodoro (id propio: sustituir los
  /// recordatorios no lo quita).
  Future<void> scheduleTimerAlert(TimerAlert alert);

  Future<void> cancelTimerAlert();

  /// Notificación fija del Pomodoro en marcha (sustituye a la anterior).
  Future<void> showOngoingTimer(OngoingTimer timer);

  Future<void> cancelOngoingTimer();

  /// `payload` de cada aviso tocado, empezando por el que abrió la app.
  Stream<String> watchOpenedPayloads();
}

/// Implementación con `flutter_local_notifications` para Android e iOS.
///
/// Programa con [AndroidScheduleMode.inexactAllowWhileIdle]: Android puede
/// retrasar unos minutos el aviso, pero no hace falta el permiso de alarmas
/// exactas (que Android 14 ya no concede por defecto). Los instantes se pasan
/// en UTC: son absolutos, así que no hace falta conocer la zona del teléfono
/// ni cargar la base de datos de zonas horarias.
class NotificationsReminderScheduler implements LocalReminderScheduler {
  NotificationsReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'synaptixfit_reminders';

  /// Canal y id del aviso del temporizador: prioridad alta (es lo que la
  /// persona está esperando) y un id fuera del rango de los recordatorios.
  static const _timerChannelId = 'synaptixfit_timer';
  static const _timerId = 2147480000;

  /// Notificación fija del Pomodoro en marcha: canal discreto (sin sonido) y
  /// otro id fuera del rango de los recordatorios.
  static const _ongoingChannelId = 'synaptixfit_timer_ongoing';
  static const _ongoingId = 2147480001;

  /// Icono del aviso. Se conserva en el build de release con `res/raw/keep.xml`.
  static const _androidIcon = '@mipmap/launcher_icon';

  final FlutterLocalNotificationsPlugin _plugin;
  final _opened = StreamController<String>.broadcast();

  /// Aviso del temporizador pendiente: se vuelve a programar si se sustituyen
  /// los recordatorios (eso cancela todo lo pendiente).
  TimerAlert? _timerAlert;
  Future<void>? _ready;
  bool _launchChecked = false;

  @override
  bool get isSupported => true;

  Future<void> _ensureReady() => _ready ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_androidIcon),
          // El permiso se pide solo al activar el interruptor de ajustes.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload case final payload?) _opened.add(payload);
        },
      )
      .then((_) {});

  @override
  Future<bool> requestPermission() async {
    await _ensureReady();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    // En Android < 13 no hay permiso que pedir y devuelve true.
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> hasPermission() async {
    await _ensureReady();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return (await ios?.checkPermissions())?.isEnabled ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<void> replaceAll(List<Reminder> reminders, String channelName) async {
    await _ensureReady();
    // Solo los pendientes: los avisos ya mostrados se quedan en la bandeja.
    await _plugin.cancelAllPendingNotifications();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(_channelId, channelName),
      iOS: const DarwinNotificationDetails(),
    );
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.at.toUtc(), tz.UTC),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.kind.payload,
      );
    }
    final alert = _timerAlert;
    if (alert != null && alert.at.isAfter(DateTime.now())) {
      await _scheduleTimer(alert);
    }
  }

  @override
  Future<void> scheduleTimerAlert(TimerAlert alert) async {
    await _ensureReady();
    _timerAlert = alert;
    await _plugin.cancel(id: _timerId);
    await _scheduleTimer(alert);
  }

  /// Exacto si Android lo permite (en Android 14 hay que concederlo en
  /// ajustes); si no, inexacto: puede llegar con algo de retraso, pero llega.
  Future<void> _scheduleTimer(TimerAlert alert) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exact = await android?.canScheduleExactNotifications() ?? true;
    await _plugin.zonedSchedule(
      id: _timerId,
      title: alert.title,
      body: alert.body,
      scheduledDate: tz.TZDateTime.from(alert.at.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _timerChannelId,
          alert.channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelTimerAlert() async {
    await _ensureReady();
    _timerAlert = null;
    await _plugin.cancel(id: _timerId);
  }

  /// Con [OngoingTimer.endsAt], Android muestra la cuenta atrás él solo
  /// (cronómetro) y la quita al llegar a cero; en pausa, solo el texto.
  @override
  Future<void> showOngoingTimer(OngoingTimer timer) async {
    // Solo Android tiene notificaciones fijas con cuenta atrás; en iOS quedaría
    // un aviso normal en el centro de notificaciones con cada cambio.
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _ensureReady();
    final end = timer.endsAt;
    final left = end?.difference(DateTime.now()).inMilliseconds;
    await _plugin.show(
      id: _ongoingId,
      title: timer.title,
      body: timer.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _ongoingChannelId,
          timer.channelName,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          silent: true,
          showWhen: end != null,
          when: end?.millisecondsSinceEpoch,
          usesChronometer: end != null,
          chronometerCountDown: end != null,
          timeoutAfter: left != null && left > 0 ? left : null,
          category: AndroidNotificationCategory.stopwatch,
        ),
        iOS: const DarwinNotificationDetails(presentSound: false),
      ),
    );
  }

  @override
  Future<void> cancelOngoingTimer() async {
    await _ensureReady();
    await _plugin.cancel(id: _ongoingId);
  }

  /// Quita los recordatorios (pendientes y mostrados) sin tocar el Pomodoro en
  /// marcha: su aviso de fin de fase se vuelve a programar y su notificación
  /// fija se queda. Al cerrar sesión, el propio Pomodoro quita los suyos.
  @override
  Future<void> cancelAll() async {
    await _ensureReady();
    await _plugin.cancelAllPendingNotifications();
    for (final shown in await _plugin.getActiveNotifications()) {
      final id = shown.id;
      if (id != null && id != _ongoingId && id != _timerId) {
        await _plugin.cancel(id: id);
      }
    }
    final alert = _timerAlert;
    if (alert != null && alert.at.isAfter(DateTime.now())) {
      await _scheduleTimer(alert);
    }
  }

  @override
  Stream<String> watchOpenedPayloads() async* {
    await _ensureReady();
    if (!_launchChecked) {
      _launchChecked = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) && payload != null) {
        yield payload;
      }
    }
    yield* _opened.stream;
  }
}

/// Web y escritorio: no hay avisos locales y todo es una operación vacía.
class NoopReminderScheduler implements LocalReminderScheduler {
  const NoopReminderScheduler();

  @override
  bool get isSupported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> replaceAll(List<Reminder> reminders, String channelName) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleTimerAlert(TimerAlert alert) async {}

  @override
  Future<void> cancelTimerAlert() async {}

  @override
  Future<void> showOngoingTimer(OngoingTimer timer) async {}

  @override
  Future<void> cancelOngoingTimer() async {}

  @override
  Stream<String> watchOpenedPayloads() => const Stream.empty();
}
