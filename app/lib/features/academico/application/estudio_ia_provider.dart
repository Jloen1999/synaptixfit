import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/estudio_ia_service.dart';

/// Servicio de asistente de estudio con IA (resúmenes y mapas mentales).
final estudioIaServiceProvider = Provider<EstudioIaService>((ref) {
  return EstudioIaService();
});
