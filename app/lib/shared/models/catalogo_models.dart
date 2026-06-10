// ---------------------------------------------------------------------------
// Modelos de catálogo para el sistema de ejercicios normalizado.
// Representan las tablas: partes_cuerpo, musculos, equipamientos.
// ---------------------------------------------------------------------------

/// Modelo para la tabla `partes_cuerpo` (catálogo de zonas corporales).
class ParteCuerpoDb {
  const ParteCuerpoDb({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory ParteCuerpoDb.fromMap(Map<String, dynamic> map) {
    return ParteCuerpoDb(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'nombre': nombre};

  @override
  String toString() => 'ParteCuerpoDb(id: $id, nombre: $nombre)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParteCuerpoDb &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Modelo para la tabla `musculos` (catálogo de músculos).
class MusculoDb {
  const MusculoDb({required this.id, required this.nombre, this.urlImagen});

  final int id;
  final String nombre;
  final String? urlImagen;

  factory MusculoDb.fromMap(Map<String, dynamic> map) {
    return MusculoDb(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      urlImagen: map['url_imagen'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        if (urlImagen != null) 'url_imagen': urlImagen,
      };

  MusculoDb copyWith({int? id, String? nombre, String? urlImagen}) {
    return MusculoDb(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      urlImagen: urlImagen ?? this.urlImagen,
    );
  }

  @override
  String toString() =>
      'MusculoDb(id: $id, nombre: $nombre, urlImagen: $urlImagen)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusculoDb && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Modelo para la tabla `equipamientos` (catálogo de equipos de gimnasio).
class EquipamientoDb {
  const EquipamientoDb({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory EquipamientoDb.fromMap(Map<String, dynamic> map) {
    return EquipamientoDb(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'nombre': nombre};

  @override
  String toString() => 'EquipamientoDb(id: $id, nombre: $nombre)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipamientoDb &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// DTO que agrupa los 3 catálogos para cargarlos de forma conjunta.
class CatalogosEjercicios {
  const CatalogosEjercicios({
    required this.partesCuerpo,
    required this.musculos,
    required this.equipamientos,
  });

  final List<ParteCuerpoDb> partesCuerpo;
  final List<MusculoDb> musculos;
  final List<EquipamientoDb> equipamientos;

  /// Retorna la lista de partes del cuerpo única y ordenada alfabéticamente.
  List<String> get partesCuerpoNombres =>
      partesCuerpo.map((p) => p.nombre).toList()..sort();

  /// Retorna la lista de músculos única y ordenada alfabéticamente.
  List<String> get musculosNombres =>
      musculos.map((m) => m.nombre).toList()..sort();

  /// Retorna la lista de equipamientos única y ordenada alfabéticamente.
  List<String> get equipamientosNombres =>
      equipamientos.map((e) => e.nombre).toList()..sort();

  /// Retorna la URL de la imagen R2 para un músculo por su nombre, o null.
  String? urlImagenMusculo(String nombre) {
    final match = musculos.cast<MusculoDb?>().firstWhere(
          (m) => m!.nombre == nombre,
          orElse: () => null,
        );
    return match?.urlImagen;
  }
}
