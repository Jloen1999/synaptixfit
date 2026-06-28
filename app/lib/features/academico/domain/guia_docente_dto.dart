import 'dart:convert';

class ProfesorGuia {
  const ProfesorGuia({
    required this.nombre,
    required this.email,
    required this.despacho,
  });

  final String nombre;
  final String email;
  final String despacho;

  factory ProfesorGuia.fromMap(Map<String, dynamic> m) => ProfesorGuia(
        nombre: (m['nombre'] as String?) ?? '',
        email: (m['email'] as String?) ?? '',
        despacho: (m['despacho'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'email': email,
        'despacho': despacho,
      };
}

enum TemaTipo { teoria, practica }

extension TemaTipoX on TemaTipo {
  String get valorDb => switch (this) {
        TemaTipo.teoria => 'teoria',
        TemaTipo.practica => 'practica',
      };

  String get etiqueta => switch (this) {
        TemaTipo.teoria => 'Teoría',
        TemaTipo.practica => 'Práctica'
      };

  static TemaTipo desde(String v) =>
      v == 'practica' ? TemaTipo.practica : TemaTipo.teoria;
}

class TemaGuia {
  const TemaGuia({
    required this.titulo,
    required this.tipo,
    this.completado = false,
  });

  final String titulo;
  final TemaTipo tipo;
  final bool completado;

  TemaGuia copyWith({String? titulo, TemaTipo? tipo, bool? completado}) =>
      TemaGuia(
        titulo: titulo ?? this.titulo,
        tipo: tipo ?? this.tipo,
        completado: completado ?? this.completado,
      );

  factory TemaGuia.fromMap(Map<String, dynamic> m) => TemaGuia(
        titulo: (m['titulo'] as String?) ?? '',
        tipo: TemaTipoX.desde((m['tipo'] as String?) ?? 'teoria'),
        completado: (m['completado'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'tipo': tipo.valorDb,
        'completado': completado,
      };
}

class CriterioEvaluacion {
  const CriterioEvaluacion({
    required this.nombre,
    required this.porcentaje,
    this.notaObtenida,
  });

  final String nombre;
  final double porcentaje;
  final double? notaObtenida;

  CriterioEvaluacion copyWith({
    String? nombre,
    double? porcentaje,
    double? notaObtenida,
  }) =>
      CriterioEvaluacion(
        nombre: nombre ?? this.nombre,
        porcentaje: porcentaje ?? this.porcentaje,
        notaObtenida: notaObtenida,
      );

  factory CriterioEvaluacion.fromMap(Map<String, dynamic> m) =>
      CriterioEvaluacion(
        nombre: (m['nombre'] as String?) ?? '',
        porcentaje: (m['porcentaje'] as num?)?.toDouble() ?? 0,
        notaObtenida: (m['nota_obtenida'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'porcentaje': porcentaje,
        if (notaObtenida != null) 'nota_obtenida': notaObtenida,
      };
}

class GuiaDocenteDto {
  const GuiaDocenteDto({
    required this.profesores,
    required this.temario,
    required this.evaluacion,
    this.bibliografia = const [],
  });

  final List<ProfesorGuia> profesores;
  final List<TemaGuia> temario;
  final List<CriterioEvaluacion> evaluacion;
  final List<String> bibliografia;

  bool get tieneDatos =>
      profesores.isNotEmpty ||
      temario.isNotEmpty ||
      evaluacion.isNotEmpty ||
      bibliografia.isNotEmpty;

  bool get todosTemasCompletados =>
      temario.isNotEmpty && temario.every((t) => t.completado);

  double get porcentajeTemario {
    if (temario.isEmpty) return 0;
    return temario.where((t) => t.completado).length / temario.length;
  }

  ({double notaEstimada, double porcentajeCubierto, String? mensaje})
      get estadoCalculadora {
    if (evaluacion.isEmpty) {
      return (notaEstimada: 0, porcentajeCubierto: 0, mensaje: null);
    }

    double notaPonderada = 0;
    double porcentajeCubierto = 0;
    double porcentajeRestante = 0;
    String? criterioFaltante;

    for (final c in evaluacion) {
      if (c.notaObtenida != null) {
        notaPonderada += (c.notaObtenida! / 10) * c.porcentaje;
        porcentajeCubierto += c.porcentaje;
      } else {
        porcentajeRestante += c.porcentaje;
        criterioFaltante ??= c.nombre;
      }
    }

    final notaEstimada = porcentajeCubierto > 0
        ? ((notaPonderada / porcentajeCubierto) * 100 / 10)
            .clamp(0, 10)
            .toDouble()
        : 0.0;

    String? mensaje;
    if (porcentajeCubierto < 100 && porcentajeRestante > 0) {
      final necesaria =
          ((50.0 - notaPonderada) / porcentajeRestante * 10).clamp(0, 10);
      mensaje =
          'Necesitas un ${necesaria.toStringAsFixed(1)} en "$criterioFaltante" para aprobar';
    }

    return (
      notaEstimada: notaEstimada,
      porcentajeCubierto: porcentajeCubierto,
      mensaje: mensaje,
    );
  }

  String toJson() => jsonEncode({
        'profesores': profesores.map((p) => p.toMap()).toList(),
        'temario': temario.map((t) => t.toMap()).toList(),
        'evaluacion': evaluacion.map((e) => e.toMap()).toList(),
        'bibliografia': bibliografia,
      });

  factory GuiaDocenteDto.fromJson(String raw) {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return GuiaDocenteDto.fromMap(m);
  }

  factory GuiaDocenteDto.fromMap(Map<String, dynamic> m) => GuiaDocenteDto(
        profesores: (m['profesores'] as List<dynamic>?)
                ?.map((e) => ProfesorGuia.fromMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
        temario: (m['temario'] as List<dynamic>?)
                ?.map((e) => TemaGuia.fromMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
        evaluacion: (m['evaluacion'] as List<dynamic>?)
                ?.map((e) =>
                    CriterioEvaluacion.fromMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
        bibliografia: (m['bibliografia'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  GuiaDocenteDto copyWith({
    List<ProfesorGuia>? profesores,
    List<TemaGuia>? temario,
    List<CriterioEvaluacion>? evaluacion,
    List<String>? bibliografia,
  }) =>
      GuiaDocenteDto(
        profesores: profesores ?? this.profesores,
        temario: temario ?? this.temario,
        evaluacion: evaluacion ?? this.evaluacion,
        bibliografia: bibliografia ?? this.bibliografia,
      );
}
