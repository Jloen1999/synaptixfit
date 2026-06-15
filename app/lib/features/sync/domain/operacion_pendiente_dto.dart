class OperacionPendiente {
  const OperacionPendiente({
    required this.id,
    required this.tabla,
    required this.operacion,
    required this.datos,
    required this.creadoEn,
    this.identificador,
    this.reintentos = 0,
  });

  final String id;
  final String tabla;
  final String operacion;
  final Map<String, dynamic> datos;
  final DateTime creadoEn;
  final String? identificador;
  final int reintentos;

  static const maxReintentos = 3;
}
