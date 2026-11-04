/// Permisos del móvil que usa la app. Se piden con una explicación antes, al
/// configurar la app y justo antes de la acción que los necesita.
enum DevicePermission {
  /// Recordatorios y avisos.
  notifications,

  /// Que los avisos lleguen a su hora exacta (Android 12+). Sin él, llegan
  /// con unos minutos de margen.
  exactAlarms,

  /// Fotografiar apuntes en papel.
  camera,
}

/// Cómo está un permiso en este dispositivo.
enum DevicePermissionStatus {
  granted,

  /// Se puede volver a pedir.
  denied,

  /// El sistema ya no lo vuelve a preguntar: solo se cambia en sus ajustes.
  permanentlyDenied,

  /// No existe en esta plataforma (web, escritorio, alarmas en iOS…): no hace
  /// falta pedirlo.
  notApplicable;

  /// Se puede usar lo que depende del permiso.
  bool get usable => this == granted || this == notApplicable;
}
