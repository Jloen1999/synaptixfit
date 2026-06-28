import 'package:flutter/material.dart';

import '../../../shared/models/db_models.dart';

/// Paleta semántica plana (Flat Design) para identificar asignaturas.
/// Tonos legibles sobre el fondo base #1A1A2E.
const List<Color> _paletaAsignaturas = [
  Color(0xFF7C9CFF), // azul
  Color(0xFF4DD0A8), // verde menta
  Color(0xFFFFB74D), // ámbar
  Color(0xFFE57399), // rosa
  Color(0xFF9C7BE0), // violeta
  Color(0xFF4DB6AC), // teal
  Color(0xFFEF7D6B), // coral
  Color(0xFF64B5F6), // celeste
  Color(0xFFF4C95D), // dorado
  Color(0xFF8BC34A), // lima
];

/// Devuelve un color estable para una asignatura derivado de su [seed]
/// (normalmente su `id`), de modo que siempre se vea con el mismo color.
Color colorAsignatura(String seed) {
  if (seed.isEmpty) return _paletaAsignaturas.first;
  var hash = 0;
  for (final code in seed.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return _paletaAsignaturas[hash % _paletaAsignaturas.length];
}

/// Calcula unas siglas cortas (2-4 caracteres) para mostrar de forma destacada.
/// Prioriza el `codigo` de la asignatura; si no existe, deriva de las iniciales
/// de las palabras significativas del nombre.
String siglasAsignatura(AsignaturaDb asignatura) {
  final codigo = asignatura.codigo?.trim() ?? '';
  if (codigo.isNotEmpty) {
    return codigo.toUpperCase().length > 6
        ? codigo.toUpperCase().substring(0, 6)
        : codigo.toUpperCase();
  }
  const ignoradas = {'de', 'la', 'el', 'y', 'a', 'del', 'los', 'las', 'e', 'i'};
  final palabras = asignatura.nombre
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !ignoradas.contains(w.toLowerCase()))
      .toList();
  if (palabras.isEmpty) {
    final n = asignatura.nombre.trim();
    return (n.isEmpty ? '?' : n.substring(0, n.length >= 2 ? 2 : 1))
        .toUpperCase();
  }
  final siglas = palabras.take(4).map((w) => w[0].toUpperCase()).join();
  return siglas;
}
