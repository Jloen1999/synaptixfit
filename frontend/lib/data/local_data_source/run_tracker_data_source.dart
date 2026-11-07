import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/models/training/run.dart';

/// GPS del móvil con `geolocator` (ADR 0037). En Android la grabación sigue
/// con la pantalla apagada mediante el servicio en primer plano del paquete
/// (tipo `location`, con su aviso fijo); nunca se pide la ubicación «siempre».
/// Puede lanzar excepciones del plugin: el repositorio las traduce.
abstract interface class RunTrackerDataSource {
  bool get supported;

  Future<bool> serviceEnabled();

  Future<RunFix?> currentPosition();

  Stream<RunFix> watch({
    required String notificationTitle,
    required String notificationText,
    required String channelName,
  });

  Future<void> updateNotification({
    required String title,
    required String text,
    required String channelName,
  });

  Future<void> vibrate();
}

/// [RunTrackerDataSource] real (Android e iOS).
class GeolocatorRunTrackerDataSource implements RunTrackerDataSource {
  GeolocatorRunTrackerDataSource([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Id y canal del aviso del servicio en primer plano de `geolocator_android`:
  /// volver a publicarlo con el mismo id cambia su texto sin crear otro aviso.
  static const _serviceNotificationId = 75415;
  static const _serviceChannelId = 'geolocator_channel_01';

  /// Un punto cada 2 s o cada 3 m como mucho: de sobra para el ritmo y la ruta,
  /// y la ruta de una hora cabe holgada en el límite del servidor.
  static const _interval = Duration(seconds: 2);
  static const _distanceFilter = 3;

  final FlutterLocalNotificationsPlugin _plugin;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  bool get supported => _android || _ios;

  @override
  Future<bool> serviceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<RunFix?> currentPosition() async {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return _fix(last);
    final now = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return _fix(now);
  }

  @override
  Stream<RunFix> watch({
    required String notificationTitle,
    required String notificationText,
    required String channelName,
  }) {
    final LocationSettings settings = _android
        ? AndroidSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: _distanceFilter,
            intervalDuration: _interval,
            foregroundNotificationConfig: ForegroundNotificationConfig(
              notificationTitle: notificationTitle,
              notificationText: notificationText,
              notificationChannelName: channelName,
              enableWakeLock: true,
              setOngoing: true,
            ),
          )
        : AppleSettings(
            accuracy: LocationAccuracy.best,
            activityType: ActivityType.fitness,
            distanceFilter: _distanceFilter,
            pauseLocationUpdatesAutomatically: false,
          );
    return Geolocator.getPositionStream(locationSettings: settings).map(_fix);
  }

  @override
  Future<void> updateNotification({
    required String title,
    required String text,
    required String channelName,
  }) async {
    if (!_android) return;
    await _plugin.show(
      id: _serviceNotificationId,
      title: title,
      body: text,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _serviceChannelId,
          channelName,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          silent: true,
          showWhen: false,
          category: AndroidNotificationCategory.workout,
        ),
      ),
    );
  }

  @override
  Future<void> vibrate() => HapticFeedback.heavyImpact();

  static RunFix _fix(Position p) => RunFix(
    latitude: p.latitude,
    longitude: p.longitude,
    altitude: p.altitude == 0 ? null : p.altitude,
    accuracy: p.accuracy,
    time: p.timestamp,
  );
}

/// En web y escritorio no se graba con GPS: la pantalla lo explica y deja
/// apuntar la actividad a mano.
class UnsupportedRunTrackerDataSource implements RunTrackerDataSource {
  const UnsupportedRunTrackerDataSource();

  @override
  bool get supported => false;

  @override
  Future<bool> serviceEnabled() async => false;

  @override
  Future<RunFix?> currentPosition() async => null;

  @override
  Stream<RunFix> watch({
    required String notificationTitle,
    required String notificationText,
    required String channelName,
  }) => const Stream.empty();

  @override
  Future<void> updateNotification({
    required String title,
    required String text,
    required String channelName,
  }) async {}

  @override
  Future<void> vibrate() async {}
}
