import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/config/app_config.dart';
import 'app/di/app_di.dart';
import 'app/synaptixfit_app.dart';
import 'domain/use_cases/profile/get_appearance_use_case.dart';
import 'domain/use_cases/profile/get_language_use_case.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Las fuentes van en assets/google_fonts: sin descargas (ni salto de
  // tipografía al cargar ni letra del sistema sin conexión).
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [
      ('Manrope', 'OFL-Manrope.txt'),
      ('DM Sans', 'OFL-DMSans.txt'),
    ]) {
      final license = await rootBundle.loadString('assets/google_fonts/$file');
      yield LicenseEntryWithLineBreaks([family], license);
    }
  });
  // Fechas en los cuatro idiomas de la app (se elige en Ajustes).
  await initializeDateFormatting();
  await appInitDi(AppConfig.fromEnvironment());
  // La apariencia se lee antes de pintar para no arrancar en oscuro y cambiar.
  final appearance =
      (await getIt<GetAppearanceUseCaseContract>()()).valueOrNull;
  final language = (await getIt<GetLanguageUseCaseContract>()()).valueOrNull;
  runApp(
    SynaptixFitApp(initialAppearance: appearance, initialLanguage: language),
  );
}
