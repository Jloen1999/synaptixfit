import 'reto_condicion_dto.dart';

class GrafoReto {
  const GrafoReto({
    required this.retoId,
    required this.nodos,
    required this.aristas,
  });

  final String retoId;
  final List<NodoHito> nodos;
  final List<AristaDependencia> aristas;
}

class NodoHito {
  const NodoHito({
    required this.hitoId,
    required this.titulo,
    required this.estado,
    required this.porcentajePeso,
    required this.estaCompletado,
    this.profundidad = 0,
  });

  final String hitoId;
  final String titulo;
  final EstadoHito estado;
  final double porcentajePeso;
  final bool estaCompletado;
  final int profundidad;
}

class AristaDependencia {
  const AristaDependencia({
    required this.desdeHitoId,
    required this.haciaHitoId,
    required this.condicion,
    this.condicionN = 1,
  });

  final String desdeHitoId;
  final String haciaHitoId;
  final TipoCondicion condicion;
  final int condicionN;
}
