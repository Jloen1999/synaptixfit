import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notificacion_dto.dart';
import '../infrastructure/notificaciones_repository.dart';

/// Proveedor del repositorio de notificaciones.
final notificacionesRepositoryProvider =
    Provider<NotificacionesRepository>((ref) {
  return const NotificacionesRepository();
});

/// Lista de notificaciones del usuario (esqueleto).
///
/// Retorna una lista vacía — la implementación real de queries a Supabase
/// se hará en un sprint futuro.
final notificacionesProvider = FutureProvider<List<Notificacion>>((ref) async {
  return [];
});
