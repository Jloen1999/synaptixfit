import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/reminders/ongoing_timer.dart';
import '../../domain/models/reminders/reminder.dart';
import '../../domain/models/reminders/timer_alert.dart';

/// Aviso tocado: su `payload` y el botón pulsado (nulo: el aviso en sí).
typedef NotificationTap = ({String payload, String? action});

/// Id del botón «Empezar» de la notificación (abre la app).
const reminderStartAction = 'start';

/// Id del botón «Posponer» (no abre la app: vuelve a programar el aviso).
const reminderSnoozeAction = 'snooze';

/// Pulsar «Posponer» con la app cerrada o en segundo plano: Android lo
/// ejecuta en un isolate aparte, sin la app abierta. Por eso es una función
/// de nivel superior y lleva en el `payload` todo lo que necesita.
@pragma('vm:entry-point')
Future<void> reminderBackgroundTap(NotificationResponse response) async {
  if (response.actionId != reminderSnoozeAction) return;
  final plugin = FlutterLocalNotificationsPlugin();
  // En el isolate de fondo el plugin debe iniciarse antes de programar; se
  // espera todo para que el isolate no termine a medias.
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings(
        NotificationsReminderScheduler.androidIcon,
      ),
    ),
  );
  await NotificationsReminderScheduler.snooze(plugin, response);
}

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

  /// Cada aviso tocado (y el botón pulsado), empezando por el que abrió la
  /// app. «Posponer» no llega aquí: se resuelve sin abrir nada.
  Stream<NotificationTap> watchOpenedPayloads();
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
  static const androidIcon = '@mipmap/launcher_icon';

  final FlutterLocalNotificationsPlugin _plugin;
  final _opened = StreamController<NotificationTap>.broadcast();

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
          android: AndroidInitializationSettings(androidIcon),
          // El permiso se pide solo al activar el interruptor de ajustes.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          // Con la app delante, «Posponer» también llega aquí.
          if (response.actionId == reminderSnoozeAction) {
            unawaited(snooze(_plugin, response));
            return;
          }
          if (response.payload case final payload?) {
            _opened.add((payload: payload, action: response.actionId));
          }
        },
        onDidReceiveBackgroundNotificationResponse: reminderBackgroundTap,
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
    // Los pospuestos que aún no han sonado se respetan: si no, abrir la app
    // en esos minutos los borraría.
    final snoozed = <int>{};
    for (final pending in await _plugin.pendingNotificationRequests()) {
      if (_isSnoozedAndWaiting(pending.payload)) {
        snoozed.add(pending.id);
      } else {
        await _plugin.cancel(id: pending.id);
      }
    }
    for (final reminder in reminders) {
      if (snoozed.contains(reminder.id)) continue;
      final snooze = reminder.hasActions
          ? _SnoozeData(
              title: reminder.title,
              body: reminder.body,
              channel: channelName,
              start: reminder.startLabel!,
              snooze: reminder.snoozeLabel!,
              minutes: reminder.snoozeMinutes,
            )
          : null;
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.at.toUtc(), tz.UTC),
        notificationDetails: _details(channelName, snooze),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: snooze == null
            ? reminder.payload
            : '${reminder.payload}|${snooze.encode()}',
      );
    }
    final alert = _timerAlert;
    if (alert != null && alert.at.isAfter(DateTime.now())) {
      await _scheduleTimer(alert);
    }
  }

  /// Detalles del aviso; con [snooze], con los botones «Empezar» (abre la
  /// app) y «Posponer» (lo vuelve a programar sin abrirla). En iOS los botones
  /// necesitan categorías registradas al iniciar: allí el aviso va sin ellos.
  static NotificationDetails _details(String channelName, _SnoozeData? snooze) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          channelName,
          actions: snooze == null
              ? null
              : [
                  AndroidNotificationAction(
                    reminderStartAction,
                    snooze.start,
                    showsUserInterface: true,
                  ),
                  AndroidNotificationAction(
                    reminderSnoozeAction,
                    snooze.snooze,
                    cancelNotification: true,
                  ),
                ],
        ),
        iOS: const DarwinNotificationDetails(),
      );

  /// Aviso pospuesto cuya nueva hora aún no ha llegado.
  static bool _isSnoozedAndWaiting(String? payload) {
    if (payload == null) return false;
    final cut = payload.lastIndexOf('|');
    final until = cut < 0
        ? null
        : _SnoozeData.decode(payload.substring(cut + 1))?.until;
    return until != null && until.isAfter(DateTime.now());
  }

  /// «Posponer»: quita el aviso y lo vuelve a programar a los minutos que
  /// lleva en su `payload`, con los mismos textos y botones. Funciona con la
  /// app cerrada ([reminderBackgroundTap]). No mira el silencio nocturno: lo
  /// pide la persona en ese momento (ADR 0013).
  static Future<void> snooze(
    FlutterLocalNotificationsPlugin plugin,
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    final id = response.id;
    if (payload == null || id == null) return;
    final cut = payload.lastIndexOf('|');
    final data = cut < 0 ? null : _SnoozeData.decode(payload.substring(cut + 1));
    if (data == null) return;
    final until = DateTime.now().toUtc().add(Duration(minutes: data.minutes));
    final again = data.copyUntil(until);
    await plugin.cancel(id: id);
    await plugin.zonedSchedule(
      id: id,
      title: data.title,
      body: data.body,
      scheduledDate: tz.TZDateTime.from(until, tz.UTC),
      notificationDetails: _details(data.channel, again),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '${payload.substring(0, cut)}|${again.encode()}',
    );
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
  Stream<NotificationTap> watchOpenedPayloads() async* {
    await _ensureReady();
    if (!_launchChecked) {
      _launchChecked = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      final payload = response?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) && payload != null) {
        yield (payload: payload, action: response?.actionId);
      }
    }
    yield* _opened.stream;
  }
}

/// Lo que hace falta para volver a mostrar un aviso pospuesto sin abrir la
/// app: textos, canal y botones. Viaja al final del `payload`, como consulta
/// URL (no lleva «|», que separa las partes del `payload`).
class _SnoozeData {
  const _SnoozeData({
    required this.title,
    required this.body,
    required this.channel,
    required this.start,
    required this.snooze,
    required this.minutes,
    this.until,
  });

  final String title;
  final String body;
  final String channel;
  final String start;
  final String snooze;
  final int minutes;

  /// Hora a la que suena tras posponerlo; nulo si no se ha pospuesto.
  final DateTime? until;

  _SnoozeData copyUntil(DateTime value) => _SnoozeData(
    title: title,
    body: body,
    channel: channel,
    start: start,
    snooze: snooze,
    minutes: minutes,
    until: value,
  );

  String encode() => Uri(
    queryParameters: {
      't': title,
      'b': body,
      'c': channel,
      's': start,
      'z': snooze,
      'm': '$minutes',
      if (until != null) 'u': '${until!.millisecondsSinceEpoch}',
    },
  ).query;

  static _SnoozeData? decode(String query) {
    final Map<String, String> q;
    try {
      q = Uri.splitQueryString(query);
    } on FormatException {
      return null;
    }
    final title = q['t'];
    final body = q['b'];
    final channel = q['c'];
    final start = q['s'];
    final snooze = q['z'];
    final minutes = int.tryParse(q['m'] ?? '');
    if (title == null ||
        body == null ||
        channel == null ||
        start == null ||
        snooze == null ||
        minutes == null) {
      return null;
    }
    return _SnoozeData(
      title: title,
      body: body,
      channel: channel,
      start: start,
      snooze: snooze,
      minutes: minutes,
      until: switch (int.tryParse(q['u'] ?? '')) {
        final int ms => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
        null => null,
      },
    );
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
  Stream<NotificationTap> watchOpenedPayloads() => const Stream.empty();
}
