enum EstadoCoincidencia { completa, parcial, ninguna }

class IcsEvento {
  final String uid;
  final String titulo;
  final String tipo;
  final DateTime dtStart;
  final DateTime? dtEnd;
  final String? descripcion;
  final String? ubicacion;
  final bool coincideAsignatura;

  const IcsEvento({
    required this.uid,
    required this.titulo,
    required this.tipo,
    required this.dtStart,
    this.dtEnd,
    this.descripcion,
    this.ubicacion,
    required this.coincideAsignatura,
  });
}

class IcsParseResult {
  final List<IcsEvento> todosLosEventos;
  final List<IcsEvento> eventosCoincidentes;
  final EstadoCoincidencia estado;

  const IcsParseResult({
    required this.todosLosEventos,
    required this.eventosCoincidentes,
    required this.estado,
  });
}
