/// DTO que representa un registro individual de auditoría administrativa.
///
/// Cada vez que un administrador realiza una acción sensible (cambio de rol,
/// wipe de datos, moderación de contenido), se crea un registro en la tabla
/// [admin_auditoria] para trazabilidad completa.
class AuditoriaRegistro {
  const AuditoriaRegistro({
    required this.id,
    required this.adminId,
    required this.accion,
    required this.entidad,
    this.entidadId,
    required this.detalle,
    required this.creadoEn,
    this.adminNombre,
  });

  final String id;
  final String adminId;
  final String accion;
  final String entidad;
  final String? entidadId;
  final Map<String, dynamic> detalle;
  final DateTime creadoEn;
  final String? adminNombre;

  /// Construye una instancia desde un mapa proveniente de Supabase.
  factory AuditoriaRegistro.fromMap(Map<String, dynamic> map) {
    return AuditoriaRegistro(
      id: map['id'] as String,
      adminId: map['admin_id'] as String,
      accion: map['accion'] as String,
      entidad: map['entidad'] as String,
      entidadId: map['entidad_id'] as String?,
      detalle: (map['detalle'] as Map?)?.cast<String, dynamic>() ?? {},
      creadoEn: DateTime.parse(map['creado_en'] as String),
      adminNombre: map['admin_nombre'] as String?,
    );
  }
}
