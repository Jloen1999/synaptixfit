import '../application/ejercicios_provider.dart';

class ParametrosObjetivo {
  final String objetivo;
  final int seriesMin;
  final int seriesMax;
  final int repsMin;
  final int repsMax;
  final int descansoMin;
  final int descansoMax;
  final double rpeMin;
  final double rpeMax;
  final double intensidadRelativa;
  final int ejerciciosPorDia;
  final bool priorizarCompuestos;
  final List<String> modalidades;
  final List<String> finalidadesEjercicio;
  final int volumenSemanalObjetivo;
  final bool admiteCircuito;

  const ParametrosObjetivo({
    required this.objetivo,
    required this.seriesMin,
    required this.seriesMax,
    required this.repsMin,
    required this.repsMax,
    required this.descansoMin,
    required this.descansoMax,
    required this.rpeMin,
    required this.rpeMax,
    required this.intensidadRelativa,
    required this.ejerciciosPorDia,
    required this.priorizarCompuestos,
    required this.modalidades,
    required this.finalidadesEjercicio,
    required this.volumenSemanalObjetivo,
    required this.admiteCircuito,
  });

  // -------------------------------------------------------
  // Defaults para ejercicios nuevos (sin datos de historial)
  // -------------------------------------------------------

  int get seriesDefault => (seriesMin + seriesMax) ~/ 2;
  int get repsDefault => (repsMin + repsMax) ~/ 2;
  int get descansoDefault => (descansoMin + descansoMax) ~/ 2;

  // -------------------------------------------------------
  // Tabla calibrada contra dataset_final.json
  // -------------------------------------------------------

  static const tabla = <String, ParametrosObjetivo>{
    'Hipertrofia Muscular': ParametrosObjetivo(
      objetivo: 'Hipertrofia Muscular',
      seriesMin: 3,
      seriesMax: 4,
      repsMin: 6,
      repsMax: 15,
      descansoMin: 60,
      descansoMax: 120,
      rpeMin: 7.0,
      rpeMax: 9.0,
      intensidadRelativa: 0.70,
      ejerciciosPorDia: 5,
      priorizarCompuestos: true,
      modalidades: ['fuerza'],
      // En el dataset: 629 ejercicios con esta finalidad, todos modalidad=fuerza
      finalidadesEjercicio: ['Hipertrofia Muscular'],
      volumenSemanalObjetivo: 15,
      admiteCircuito: false,
    ),
    'Fuerza Máxima': ParametrosObjetivo(
      objetivo: 'Fuerza Máxima',
      seriesMin: 3,
      seriesMax: 5,
      repsMin: 1,
      repsMax: 6,
      descansoMin: 120,
      descansoMax: 300,
      rpeMin: 8.0,
      rpeMax: 9.5,
      intensidadRelativa: 0.85,
      ejerciciosPorDia: 3,
      priorizarCompuestos: true,
      modalidades: ['fuerza'],
      // En el dataset: 301 ejercicios con esta finalidad, todos modalidad=fuerza
      finalidadesEjercicio: ['Fuerza Máxima'],
      volumenSemanalObjetivo: 10,
      admiteCircuito: false,
    ),
    'Potencia y Explosividad': ParametrosObjetivo(
      objetivo: 'Potencia y Explosividad',
      seriesMin: 3,
      seriesMax: 5,
      repsMin: 1,
      repsMax: 5,
      descansoMin: 120,
      descansoMax: 240,
      rpeMin: 7.0,
      rpeMax: 8.5,
      intensidadRelativa: 0.75,
      ejerciciosPorDia: 3,
      priorizarCompuestos: true,
      modalidades: ['metabolica'],
      // En el dataset: 27 ejercicios con esta finalidad, todos modalidad=metabolica
      finalidadesEjercicio: ['Potencia y Explosividad'],
      volumenSemanalObjetivo: 8,
      admiteCircuito: true,
    ),
    'Fuerza Resistencia': ParametrosObjetivo(
      objetivo: 'Fuerza Resistencia',
      seriesMin: 2,
      seriesMax: 3,
      repsMin: 12,
      repsMax: 25,
      descansoMin: 30,
      descansoMax: 60,
      rpeMin: 5.0,
      rpeMax: 7.0,
      intensidadRelativa: 0.55,
      ejerciciosPorDia: 6,
      priorizarCompuestos: false,
      modalidades: ['fuerza'],
      // En el dataset: 271 ejercicios con esta finalidad, todos modalidad=fuerza
      finalidadesEjercicio: ['Fuerza Resistencia'],
      volumenSemanalObjetivo: 12,
      admiteCircuito: false,
    ),
    'Movilidad y Flexibilidad': ParametrosObjetivo(
      objetivo: 'Movilidad y Flexibilidad',
      seriesMin: 2,
      seriesMax: 3,
      repsMin: 8,
      repsMax: 15,
      descansoMin: 30,
      descansoMax: 60,
      rpeMin: 3.0,
      rpeMax: 5.0,
      intensidadRelativa: 0.30,
      ejerciciosPorDia: 7,
      priorizarCompuestos: false,
      modalidades: ['movilidad'],
      // En el dataset: 102 ejercicios con esta finalidad, todos modalidad=movilidad
      finalidadesEjercicio: ['Movilidad y Flexibilidad'],
      volumenSemanalObjetivo: 6,
      admiteCircuito: false,
    ),
    'Estabilidad y Control Motor': ParametrosObjetivo(
      objetivo: 'Estabilidad y Control Motor',
      seriesMin: 2,
      seriesMax: 3,
      repsMin: 6,
      repsMax: 12,
      descansoMin: 45,
      descansoMax: 90,
      rpeMin: 4.0,
      rpeMax: 6.0,
      intensidadRelativa: 0.40,
      ejerciciosPorDia: 6,
      priorizarCompuestos: false,
      modalidades: ['fuerza'],
      // En el dataset: 187 ejercicios con esta finalidad, todos modalidad=fuerza
      finalidadesEjercicio: ['Estabilidad y Control Motor'],
      volumenSemanalObjetivo: 8,
      admiteCircuito: false,
    ),
    'Acondicionamiento Metabólico': ParametrosObjetivo(
      objetivo: 'Acondicionamiento Metabólico',
      seriesMin: 2,
      seriesMax: 3,
      repsMin: 12,
      repsMax: 25,
      descansoMin: 20,
      descansoMax: 45,
      rpeMin: 6.0,
      rpeMax: 8.0,
      intensidadRelativa: 0.50,
      ejerciciosPorDia: 5,
      priorizarCompuestos: true,
      modalidades: ['aerobica'],
      // En el dataset: 24 ejercicios con esta finalidad, todos modalidad=aerobica, circuito=true
      finalidadesEjercicio: ['Acondicionamiento Metabólico'],
      volumenSemanalObjetivo: 10,
      admiteCircuito: true,
    ),
  };

  // -------------------------------------------------------
  // Factory
  // -------------------------------------------------------

  factory ParametrosObjetivo.de(String objetivo) {
    final o = sanitizarObjetivo(objetivo);
    return tabla[o] ?? tabla['Hipertrofia Muscular'] ?? tabla.values.first;
  }
}
