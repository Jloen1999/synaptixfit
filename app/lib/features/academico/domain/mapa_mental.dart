/// Nodo de un mapa mental: una etiqueta concisa y sus sub-nodos.
class NodoMental {
  const NodoMental({
    required this.id,
    required this.titulo,
    required this.hijos,
  });

  /// Identificador estable por ruta (p. ej. "0", "0.1", "0.1.2").
  final String id;
  final String titulo;
  final List<NodoMental> hijos;

  bool get tieneHijos => hijos.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'hijos': hijos.map((h) => h.toJson()).toList(),
      };
}

/// Mapa mental jerárquico generado por la IA: un tema central + ramas.
class MapaMental {
  const MapaMental({required this.central, required this.ramas});

  final String central;
  final List<NodoMental> ramas;

  bool get vacio => ramas.isEmpty;

  Map<String, dynamic> toJson() => {
        'central': central,
        'ramas': ramas.map((r) => r.toJson()).toList(),
      };

  /// Construye el mapa desde el JSON devuelto por la IA. Es tolerante: ignora
  /// nodos malformados y limita la profundidad a 3 niveles.
  factory MapaMental.fromJson(Map<String, dynamic> json) {
    final centralRaw = (json['central'] as String?)?.trim();
    final ramasRaw = json['ramas'];

    final ramas = <NodoMental>[];
    if (ramasRaw is List) {
      for (var i = 0; i < ramasRaw.length; i++) {
        final nodo = _parseNodo(ramasRaw[i], '$i', 1);
        if (nodo != null) ramas.add(nodo);
      }
    }

    return MapaMental(
      central: (centralRaw == null || centralRaw.isEmpty)
          ? 'Mapa mental'
          : centralRaw,
      ramas: ramas,
    );
  }

  static NodoMental? _parseNodo(dynamic raw, String id, int profundidad) {
    if (raw is! Map) return null;
    final titulo = (raw['titulo'] as String?)?.trim();
    if (titulo == null || titulo.isEmpty) return null;

    final hijos = <NodoMental>[];
    if (profundidad < 3) {
      final hijosRaw = raw['hijos'];
      if (hijosRaw is List) {
        for (var i = 0; i < hijosRaw.length; i++) {
          final hijo = _parseNodo(hijosRaw[i], '$id.$i', profundidad + 1);
          if (hijo != null) hijos.add(hijo);
        }
      }
    }
    return NodoMental(id: id, titulo: titulo, hijos: hijos);
  }
}
