/// DTO que representa el perfil público del usuario.
class PerfilUsuarioDto {
  final String id;
  final String nombre;
  final String email;
  final String? avatarUrl;
  final int nivel;
  final int xp;
  final int racha;

  const PerfilUsuarioDto({
    required this.id,
    required this.nombre,
    required this.email,
    this.avatarUrl,
    required this.nivel,
    required this.xp,
    required this.racha,
  });
}
