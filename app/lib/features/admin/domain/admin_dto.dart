/// DTO que representa un usuario desde la perspectiva del panel de administración.
///
/// Incluye todos los campos necesarios para listar, buscar y mostrar
/// información resumida de cada usuario registrado en la plataforma.
class UsuarioAdmin {
  final String id;
  final String email;
  final String nombreCompleto;
  final String? urlAvatar;
  final String rol;
  final int nivel;
  final int xpTotal;
  final int rachaActual;
  final bool isShadowbanned;
  final DateTime creadoEn;

  const UsuarioAdmin({
    required this.id,
    required this.email,
    required this.nombreCompleto,
    this.urlAvatar,
    required this.rol,
    required this.nivel,
    required this.xpTotal,
    required this.rachaActual,
    required this.isShadowbanned,
    required this.creadoEn,
  });

  /// Construye una instancia desde un mapa proveniente de Supabase.
  factory UsuarioAdmin.fromMap(Map<String, dynamic> map) {
    return UsuarioAdmin(
      id: map['id'] as String,
      email: map['email'] as String,
      nombreCompleto: map['nombre_completo'] as String,
      urlAvatar: map['url_avatar'] as String?,
      rol: (map['rol'] as String?) ?? 'usuario',
      nivel: (map['nivel'] as num?)?.toInt() ?? 1,
      xpTotal: (map['xp_total'] as num?)?.toInt() ?? 0,
      rachaActual: (map['racha_actual'] as num?)?.toInt() ?? 0,
      isShadowbanned: map['is_shadowbanned'] == true,
      creadoEn: DateTime.parse(map['creado_en'] as String),
    );
  }
}
