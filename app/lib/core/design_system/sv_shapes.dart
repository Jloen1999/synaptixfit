import 'package:flutter/material.dart';

class SVShapes {
  // 8px
  static const double radiusStandard = 8.0;
  static const BorderRadius standard =
      BorderRadius.all(Radius.circular(radiusStandard));

  // 12px — inputs, tarjetas pequeñas
  static const double radiusStandard12 = 12.0;
  static const BorderRadius standard12 =
      BorderRadius.all(Radius.circular(radiusStandard12));

  // 16px — tarjetas grandes, modales
  static const double radiusLarge16 = 16.0;
  static const BorderRadius large16 =
      BorderRadius.all(Radius.circular(radiusLarge16));

  // 20px — heroes, cabeceras
  static const double radiusXLarge = 20.0;
  static const BorderRadius xLarge =
      BorderRadius.all(Radius.circular(radiusXLarge));

  // 24px — elementos destacados
  static const double radiusHuge = 24.0;
  static const BorderRadius huge =
      BorderRadius.all(Radius.circular(radiusHuge));

  // Pills — botones, chips
  static const double radiusPill = 9999.0;
  static const BorderRadius pill =
      BorderRadius.all(Radius.circular(radiusPill));

  // Obsoleto — mantener compatibilidad
  @Deprecated('Usar large16 en su lugar')
  static const double radiusLarge = 16.0;
  @Deprecated('Usar large16 en su lugar')
  static const BorderRadius large =
      BorderRadius.all(Radius.circular(radiusLarge));
}
