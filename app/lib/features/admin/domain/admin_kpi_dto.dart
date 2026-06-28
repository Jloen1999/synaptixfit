/// DTO para las métricas globales del panel de administración.
///
/// Representa los KPIs principales obtenidos desde la vista [v_admin_metricas]:
/// usuarios totales, actividad diaria, rutinas/retos activos y contenido reportado.
class AdminMetricasGlobales {
  const AdminMetricasGlobales({
    required this.totalUsuarios,
    required this.usuariosActivosHoy,
    required this.sesionesHoy,
    required this.rutinasActivas,
    required this.retosActivos,
    required this.contenidoReportadoPendiente,
  });

  final int totalUsuarios;
  final int usuariosActivosHoy;
  final int sesionesHoy;
  final int rutinasActivas;
  final int retosActivos;
  final int contenidoReportadoPendiente;

  /// Construye una instancia desde un mapa proveniente de Supabase.
  factory AdminMetricasGlobales.fromMap(Map<String, dynamic> map) {
    return AdminMetricasGlobales(
      totalUsuarios: (map['total_usuarios'] as num?)?.toInt() ?? 0,
      usuariosActivosHoy: (map['usuarios_activos_hoy'] as num?)?.toInt() ?? 0,
      sesionesHoy: (map['sesiones_hoy'] as num?)?.toInt() ?? 0,
      rutinasActivas: (map['rutinas_activas'] as num?)?.toInt() ?? 0,
      retosActivos: (map['retos_activos'] as num?)?.toInt() ?? 0,
      contenidoReportadoPendiente:
          (map['contenido_reportado_pendiente'] as num?)?.toInt() ?? 0,
    );
  }
}
