/// Tipos de eventos que pueden aparecer en la línea de tiempo de un usuario.
enum TimelineTipoAdmin {
  sesion,
  rutina,
  reto,
  insignia,
  logro,
  wipe,
  rolCambio,
}

/// DTO que representa una entrada en la línea de tiempo de un usuario.
///
/// Cada entrada tiene una fecha, un tipo de evento y una descripción legible.
class AdminTimelineEntry {
  const AdminTimelineEntry({
    required this.fecha,
    required this.tipo,
    required this.descripcion,
  });

  final DateTime fecha;
  final TimelineTipoAdmin tipo;
  final String descripcion;

  /// Construye una instancia desde un mapa, especificando el [tipo] de evento.
  factory AdminTimelineEntry.fromMap(
    Map<String, dynamic> map, {
    required TimelineTipoAdmin tipo,
  }) {
    return AdminTimelineEntry(
      fecha: DateTime.parse(map['fecha'] as String),
      tipo: tipo,
      descripcion: map['descripcion'] as String? ?? '',
    );
  }
}
