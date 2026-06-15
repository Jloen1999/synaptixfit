/// Representa una insignia del catálogo, con flag de obtenida o no.
class Insignia {
  final String id;
  final String nombre;
  final String descripcion;
  final String icono;
  final String categoria;
  final String criterioTipo;
  final int criterioValor;
  final String rareza;
  final int orden;
  final bool obtenida;
  final DateTime? obtenidaEn;

  const Insignia({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.categoria,
    required this.criterioTipo,
    required this.criterioValor,
    required this.rareza,
    required this.orden,
    this.obtenida = false,
    this.obtenidaEn,
  });

  /// Construye desde un map de BD (LEFT JOIN con usuario_insignias).
  factory Insignia.fromMap(Map<String, dynamic> map,
      {bool obtenida = false, DateTime? obtenidaEn}) {
    return Insignia(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String,
      icono: map['icono'] as String? ?? '🏅',
      categoria: map['categoria'] as String,
      criterioTipo: map['criterio_tipo'] as String,
      criterioValor: (map['criterio_valor'] as num?)?.toInt() ?? 1,
      rareza: map['rareza'] as String? ?? 'comun',
      orden: (map['orden'] as num?)?.toInt() ?? 0,
      obtenida: obtenida,
      obtenidaEn: obtenidaEn,
    );
  }

  /// Color asociado a la rareza.
  int get colorRareza {
    switch (rareza) {
      case 'legendaria':
        return 0xFFFBBF24; // dorado
      case 'epica':
        return 0xFFA78BFA; // púrpura
      case 'rara':
        return 0xFF60A5FA; // azul
      default:
        return 0xFF4ADE80; // verde (común)
    }
  }
}

/// Estado de la racha diaria del usuario.
class RachaState {
  final int diasConsecutivos;
  final int mejorRacha;
  final bool enRiesgo;
  final int? proximoHito;
  final int diasParaProximoHito;
  final double progresoHito;

  const RachaState({
    required this.diasConsecutivos,
    required this.mejorRacha,
    this.enRiesgo = false,
    this.proximoHito,
    this.diasParaProximoHito = 0,
    this.progresoHito = 0.0,
  });

  /// Etiqueta del próximo hito (ej: "7 días", "30 días").
  String get etiquetaProximoHito {
    if (proximoHito == null) return '—';
    return '$proximoHito días';
  }
}
