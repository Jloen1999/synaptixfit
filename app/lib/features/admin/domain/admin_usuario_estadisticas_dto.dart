/// DTO que representa un punto de datos para gráficos de estadísticas de usuario.
///
/// Cada instancia contiene una fecha, un valor numérico y una etiqueta descriptiva.
class AdminDataPoint {
  const AdminDataPoint({
    required this.fecha,
    required this.valor,
    required this.etiqueta,
  });

  final DateTime fecha;
  final double valor;
  final String etiqueta;
}

/// DTO que agrupa las estadísticas semanales de un usuario.
///
/// Contiene una lista de [AdminDataPoint] para representar la evolución
/// temporal, junto con métricas agregadas como el promedio diario y la tendencia.
class AdminUsuarioEstadisticas {
  const AdminUsuarioEstadisticas({
    required this.semanas,
    this.promedioDiario = 0,
    this.tendencia = 'estable',
  });

  final List<AdminDataPoint> semanas;
  final double promedioDiario;
  final String tendencia;
}
