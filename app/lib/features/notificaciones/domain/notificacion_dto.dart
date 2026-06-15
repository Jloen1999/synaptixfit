/// DTO que representa una notificación push o in-app.
class Notificacion {
  final String id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final String? urlAccion;
  final bool leida;
  final DateTime fecha;

  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.urlAccion,
    required this.leida,
    required this.fecha,
  });
}
