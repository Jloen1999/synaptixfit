import '../domain/notificacion_dto.dart';

/// Repositorio de notificaciones (esqueleto).
///
/// Los métodos stub lanzan [UnimplementedError] — la implementación real
/// de queries a Supabase se hará en un sprint futuro.
class NotificacionesRepository {
  const NotificacionesRepository();

  /// Obtiene las notificaciones del usuario autenticado.
  Future<List<Notificacion>> obtenerNotificaciones() {
    throw UnimplementedError('obtenerNotificaciones() — sprint pendiente');
  }

  /// Marca una notificación como leída.
  Future<void> marcarComoLeida(String notificacionId) {
    throw UnimplementedError('marcarComoLeida() — sprint pendiente');
  }
}
