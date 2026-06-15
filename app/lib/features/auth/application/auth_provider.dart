import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/auth_repository.dart';

export '../infrastructure/auth_repository.dart' show AuthRepository;

// ---------------------------------------------------------------------------
// Proveedor del repositorio de autenticacion.
// Rompe la dependencia directa presentacion → infraestructura.
// ---------------------------------------------------------------------------

/// Expone una instancia del repositorio de autenticacion para que las
/// pantallas de presentacion no importen directamente la capa de
/// infraestructura.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});
