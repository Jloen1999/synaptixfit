import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/reminders/reminder.dart';

/// Acceso técnico a las notificaciones locales del sistema. Lo usa
/// `ReminderSchedulerRepository`; puede lanzar excepciones del plugin.
abstract interface class LocalReminderScheduler {
  bool get isSupported;

  Future<bool> requestPermission();

  Future<bool> hasPermission();

  Future<void> replaceAll(List<Reminder> reminders, String channelName);

  Future<void> cancelAll();

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

  /// Icono del aviso. Se conserva en el build de release con `res/raw/keep.xml`.
  static const _androidIcon = '@mipmap/launcher_icon';

  final FlutterLocalNotificationsPlugin _plugin;
  final _opened = StreamController<String>.broadcast();
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
  }

  @override
  Future<void> cancelAll() async {
    await _ensureReady();
    await _plugin.cancelAll();
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
  Stream<String> watchOpenedPayloads() => const Stream.empty();
}
