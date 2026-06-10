String normalizeSearch(String s) {
  return s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('à', 'a')
      .replaceAll('è', 'e')
      .replaceAll('ì', 'i')
      .replaceAll('ò', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('â', 'a')
      .replaceAll('ê', 'e')
      .replaceAll('î', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('û', 'u')
      .replaceAll('ä', 'a')
      .replaceAll('ë', 'e')
      .replaceAll('ï', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ã', 'a')
      .replaceAll('õ', 'o')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c');
}

// ---------------------------------------------------------------------------
// Finalidades estándar — compartidas entre ejercicios, rutinas y perfiles.
// Coinciden con los 7 valores de finalidad en dataset_final.json.
// ---------------------------------------------------------------------------

const finalidadesEstandar = [
  'Hipertrofia Muscular',
  'Fuerza Máxima',
  'Potencia y Explosividad',
  'Fuerza Resistencia',
  'Movilidad y Flexibilidad',
  'Estabilidad y Control Motor',
  'Acondicionamiento Metabólico',
];

String sanitizarObjetivo(String raw) {
  final l = normalizeSearch(raw);
  for (final f in finalidadesEstandar) {
    if (normalizeSearch(f) == l) return f;
  }
  const legacyMap = {
    'hipertrofia': 'Hipertrofia Muscular',
    'fuerza': 'Fuerza Máxima',
    'ganar_masa': 'Hipertrofia Muscular',
    'perder_peso': 'Acondicionamiento Metabólico',
    'resistencia': 'Fuerza Resistencia',
    'movilidad': 'Movilidad y Flexibilidad',
    'fitness_general': 'Estabilidad y Control Motor',
    'mixto': 'Hipertrofia Muscular',
    'cardio': 'Acondicionamiento Metabólico',
    'flexibilidad': 'Movilidad y Flexibilidad',
  };
  return legacyMap[l] ?? 'Hipertrofia Muscular';
}
