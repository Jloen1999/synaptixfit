import 'package:get_it/get_it.dart';

import '../../data/di/data_di.dart';
import '../../domain/di/domain_di.dart';
import '../../presentation/di/presentation_di.dart';
import '../config/app_config.dart';

/// Contenedor de dependencias de la aplicación.
final GetIt getIt = GetIt.instance;

/// Raíz de composición: data → domain → presentation (cada capa resuelve lo
/// que registró la anterior).
Future<void> appInitDi(AppConfig config) async {
  getIt.registerSingleton<AppConfig>(config);
  registerData(getIt, config);
  registerDomain(getIt);
  registerPresentation(getIt);
}
