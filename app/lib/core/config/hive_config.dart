import 'package:hive_flutter/hive_flutter.dart';

/// Configuración centralizada de Hive.
/// Encapsula la inicialización y apertura de boxes para evitar dispersión en main.dart.
class HiveConfig {
  HiveConfig._();

  /// Inicializa Hive en Flutter y abre los boxes necesarios.
  ///
  /// [smartcache] — caché inteligente de respuestas de IA.
  /// [offline_dash] — datos del dashboard para modo offline.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>('smartcache'),
      Hive.openBox<Map>('offline_dash'),
    ]);
  }
}
