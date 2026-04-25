import 'package:flutter/material.dart';

class SVShapes {
  // Border radius estándar (8px)
  static const double radiusStandard = 8.0;
  static const BorderRadius standard = BorderRadius.all(Radius.circular(radiusStandard));

  // Border radius pills (botones)
  static const double radiusPill = 9999.0;
  static const BorderRadius pill = BorderRadius.all(Radius.circular(radiusPill));

  // Border radius grandes (modals, bottom sheets)
  static const double radiusLarge = 16.0;
  static const BorderRadius large = BorderRadius.all(Radius.circular(radiusLarge));
}
