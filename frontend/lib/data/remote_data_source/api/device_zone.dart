/// Zona del móvil para los endpoints que cuentan días («en 3 días», días de
/// clase): el desfase actual respecto a UTC («+01:00»), que el servidor acepta
/// como zona. Sin una librería de zonas IANA es lo más fiable que da el
/// sistema; el cambio de hora solo mueve una hora la cuenta.
String deviceZoneOffset([DateTime? now]) {
  final offset = (now ?? DateTime.now()).timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  final hh = (minutes ~/ 60).toString().padLeft(2, '0');
  final mm = (minutes % 60).toString().padLeft(2, '0');
  return '$sign$hh:$mm';
}
