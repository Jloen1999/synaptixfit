import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/config/app_config.dart';
import 'app/di/app_di.dart';
import 'app/synaptixfit_app.dart';

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
  await initializeDateFormatting('es');
  await appInitDi(AppConfig.fromEnvironment());
  runApp(const SynaptixFitApp());
}
