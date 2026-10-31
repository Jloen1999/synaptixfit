import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Configuración común de los tests: fechas y números en español, como la
/// app cuando el idioma resuelto es el español (en la app lo fija
/// `SynaptixFitApp` al resolver el idioma; en los tests no hay app raíz).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  Intl.defaultLocale = 'es';
  await testMain();
}
