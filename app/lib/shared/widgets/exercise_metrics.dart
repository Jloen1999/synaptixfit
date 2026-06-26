import 'package:flutter/material.dart';

import '../../features/bienestar/infrastructure/calorie_calculator_service.dart';

/// Categoría de ejercicio que determina cómo se agrupan y muestran las métricas.
enum ExerciseMetricCategoria { fuerza, aerobico, isometrico, circuito }

extension ExerciseMetricCategoriaResolver on ExerciseMetricCategoria {
  /// Deriva la categoría a partir de la modalidad de entrenamiento del catálogo,
  /// el tipo de medición y si es circuito.
  static ExerciseMetricCategoria desdeModalidad(
    String modalidad, {
    List<String> tipoMedicion = const [],
    bool esCircuito = false,
  }) {
    if (esCircuito) return ExerciseMetricCategoria.circuito;
    final hasTiempo = tipoMedicion.contains('tiempo');
    final hasReps = tipoMedicion.contains('repeticiones');
    final hasDistancia = tipoMedicion.contains('distancia');
    final hasCalorias = tipoMedicion.contains('calorias');
    if (hasTiempo && !hasReps && !hasDistancia && !hasCalorias) {
      return ExerciseMetricCategoria.isometrico;
    }
    final m = modalidad.toLowerCase();
    if (m.contains('movilidad') ||
        m.contains('flexibilidad') ||
        m.contains('isometric')) {
      return ExerciseMetricCategoria.isometrico;
    }
    if (m.contains('aerobic') ||
        m.contains('metabolic') ||
        m.contains('cardio') ||
        hasDistancia ||
        hasCalorias) {
      return ExerciseMetricCategoria.aerobico;
    }
    return ExerciseMetricCategoria.fuerza;
  }

  /// Deriva la categoría a partir de la finalidad principal del ejercicio.
  static ExerciseMetricCategoria desdeFinalidad(
    String finalidad, {
    bool esCircuito = false,
  }) {
    final l = finalidad.toLowerCase();
    if (l.contains('cardio') || l.contains('acondicionamiento')) {
      return ExerciseMetricCategoria.aerobico;
    }
    if (l.contains('isometric') ||
        l.contains('movilidad') ||
        l.contains('flexibilidad') ||
        l.contains('estabilidad')) {
      return ExerciseMetricCategoria.isometrico;
    }
    if (esCircuito) return ExerciseMetricCategoria.circuito;
    return ExerciseMetricCategoria.fuerza;
  }
}

/// Micro-chip semántico (Flat Design): icono pequeño + texto.
///
/// Fondo tenue (12% del color primario), sin sombras y esquinas totalmente
/// redondeadas (borderRadius: 100).
class SemanticMicroChip extends StatelessWidget {
  const SemanticMicroChip({
    required this.icon,
    required this.label,
    this.color,
    this.dense = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    final iconSize = dense ? 13.0 : 14.0;
    final fontSize = dense ? 11.0 : 12.0;
    final padH = dense ? 7.0 : 8.0;
    final padV = dense ? 3.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: base),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: base,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de métricas de un ejercicio renderizada como micro-chips semánticos.
///
/// Aplica renderizado condicional (cero ruido): omite cualquier métrica nula o
/// igual a 0. La agrupación de series/reps/tiempo depende de [categoria].
class ExerciseMetricsRow extends StatelessWidget {
  const ExerciseMetricsRow({
    required this.categoria,
    this.series,
    this.repeticiones,
    this.pesoKg,
    this.pesosKg,
    this.segundosDescanso,
    this.duracionSegundos,
    this.distanciaMetros,
    this.tiempoIsometricoSegundos,
    this.color,
    this.dense = false,
    super.key,
  });

  final ExerciseMetricCategoria categoria;
  final int? series;
  final int? repeticiones;
  final double? pesoKg;
  final List<double>? pesosKg;
  final int? segundosDescanso;
  final int? duracionSegundos;
  final int? distanciaMetros;
  final int? tiempoIsometricoSegundos;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final chips = _construirChips();
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  List<Widget> _construirChips() {
    final chips = <Widget>[];
    final s = series ?? 0;
    final reps = repeticiones ?? 0;
    final desc = segundosDescanso ?? 0;
    final dur = duracionSegundos ?? 0;
    final dist = distanciaMetros ?? 0;
    final iso = tiempoIsometricoSegundos ?? 0;

    SemanticMicroChip chip(IconData icon, String label) =>
        SemanticMicroChip(icon: icon, label: label, color: color, dense: dense);

    switch (categoria) {
      case ExerciseMetricCategoria.fuerza:
        if (s > 0 && reps > 0) {
          chips.add(chip(Icons.repeat, '$s × $reps'));
        }
        final peso = _fmtPeso(pesoKg, pesosKg);
        if (peso != null) chips.add(chip(Icons.fitness_center, '$peso kg'));
        if (desc > 0) chips.add(chip(Icons.pause_circle_outline, '${desc}s'));

      case ExerciseMetricCategoria.aerobico:
        if (dist > 0) chips.add(chip(Icons.route, _fmtDistancia(dist)));
        if (dur > 0) chips.add(chip(Icons.timer_outlined, _fmtDuracion(dur)));
        if (s > 1) chips.add(chip(Icons.loop, '$s rondas'));
        if (desc > 0) chips.add(chip(Icons.pause_circle_outline, '${desc}s'));

      case ExerciseMetricCategoria.isometrico:
        if (iso > 0) {
          chips.add(chip(Icons.timer, s > 0 ? '$s × ${iso}s' : '${iso}s'));
        } else if (s > 0 && reps > 0) {
          chips.add(chip(Icons.repeat, '$s × $reps'));
        }
        if (desc > 0) chips.add(chip(Icons.pause_circle_outline, '${desc}s'));

      case ExerciseMetricCategoria.circuito:
        if (s > 1) chips.add(chip(Icons.repeat, '$s rondas'));
        if (dur > 0) chips.add(chip(Icons.timer_outlined, _fmtDuracion(dur)));
        if (desc > 0) chips.add(chip(Icons.pause_circle_outline, '${desc}s'));
    }

    return chips;
  }
}

String _fmtDuracion(int segundos) {
  if (segundos >= 60) {
    final min = segundos ~/ 60;
    final sec = segundos % 60;
    if (sec == 0) return '$min min';
    return '${min}m ${sec}s';
  }
  return '${segundos}s';
}

String _fmtDistancia(int metros) {
  if (metros >= 1000) {
    final km = metros / 1000;
    final str = km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1);
    return '$str km';
  }
  return '$metros m';
}

String? _fmtPeso(double? pesoKg, List<double>? pesosKg) {
  if (pesosKg != null && pesosKg.any((w) => w > 0)) {
    return pesosKg
        .where((w) => w > 0)
        .map((w) => w.toStringAsFixed(w == w.roundToDouble() ? 0 : 1))
        .join('/');
  }
  if (pesoKg != null && pesoKg > 0) {
    return pesoKg.toStringAsFixed(pesoKg == pesoKg.roundToDouble() ? 0 : 1);
  }
  return null;
}

/// Micro-chip semántico de calorías estimadas basado en el estándar MET.
///
/// Muestra la estimación calórica total de un bloque o grupo de bloques
/// formateada como `"🔥 320 kcal"`. Se oculta si el valor es 0 o nulo.
///
/// El color de fondo es naranja semántico con opacidad del 15% y el
/// texto sólido con `FontWeight.w600`.
class SemantiCalorieChip extends StatelessWidget {
  const SemantiCalorieChip({
    required this.calorias,
    this.esEstimado = false,
    this.dense = false,
    super.key,
  });

  /// Calorías estimadas totales. Si es 0 o nulo, el widget no se renderiza.
  final double? calorias;

  /// Si es true, muestra el sufijo (est.) para indicar proyección.
  final bool esEstimado;

  final bool dense;

  static const _colorNaranja = Color(0xFFE67E22);
  static const _colorGris = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final kcal = calorias;
    if (kcal == null || kcal <= 0) return const SizedBox.shrink();

    final iconSize = dense ? 13.0 : 14.0;
    final fontSize = dense ? 11.0 : 12.0;
    final padH = dense ? 7.0 : 8.0;
    final padV = dense ? 3.0 : 4.0;
    final colorFondo = esEstimado
        ? _colorGris.withValues(alpha: 0.12)
        : _colorNaranja.withValues(alpha: 0.15);
    final colorTexto = esEstimado ? _colorGris : _colorNaranja;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.local_fire_department, size: iconSize, color: colorTexto),
          const SizedBox(width: 4),
          Text(
            esEstimado
                ? '~${kcal.round()} kcal (est.)'
                : '${kcal.round()} kcal',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: colorTexto,
            ),
          ),
        ],
      ),
    );
  }
}

/// Calcula y construye un chip de calorías para un bloque de ejercicio.
///
/// Usa [CalorieCalculatorService] aplicando la fórmula:
///   valorMet × pesoKg × (duracionSegundos / 3600)
///
/// Si [duracionRealSegundos] está presente se usa para el cálculo real;
/// en caso contrario se usa [duracionSegundos] como proyección con el
/// sufijo (est.).
///
/// Parámetros:
/// - [valorMet]: coeficiente MET del ejercicio (se deriva si es nulo).
/// - [pesoUsuarioKg]: peso corporal del usuario.
/// - [duracionSegundos]: duración planificada del bloque.
/// - [duracionRealSegundos]: duración real medida (tiene prioridad).
/// - [dense]: modo compacto para listas densas.
Widget buildCalorieChip({
  double? valorMet,
  required double? pesoUsuarioKg,
  required int? duracionSegundos,
  int? duracionRealSegundos,
  String modalidad = 'fuerza',
  bool esCircuito = false,
  bool dense = false,
}) {
  final durReal = duracionRealSegundos;
  final durObj = duracionSegundos ?? 0;
  final dur = durReal ?? durObj;
  if (dur <= 0) return const SizedBox.shrink();

  final met = CalorieCalculatorService.derivarMet(
    valorMet: valorMet,
    modalidad: modalidad,
    esCircuito: esCircuito,
  );

  final calorias = CalorieCalculatorService.calcular(
    valorMet: met,
    pesoUsuarioKg: pesoUsuarioKg,
    duracionSegundos: dur,
  );

  return SemantiCalorieChip(
    calorias: calorias,
    esEstimado: durReal == null,
    dense: dense,
  );
}
