import '../domain/perfil_usuario_dto.dart';

/// Repositorio de datos del perfil de usuario (esqueleto).
///
/// Los métodos stub lanzan [UnimplementedError] — la implementación real
/// de queries a Supabase se hará en un sprint futuro.
class PerfilRepository {
  const PerfilRepository();

  /// Obtiene el perfil del usuario autenticado.
  Future<PerfilUsuarioDto?> obtenerPerfil() {
    throw UnimplementedError('obtenerPerfil() — sprint pendiente');
  }

  /// Actualiza campos del perfil del usuario.
  Future<void> actualizarPerfil(Map<String, dynamic> campos) {
    throw UnimplementedError('actualizarPerfil() — sprint pendiente');
  }
}
