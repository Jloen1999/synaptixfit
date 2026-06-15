import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/social_dto.dart';
import '../infrastructure/social_repository.dart';

// ---------------------------------------------------------------------------
// Provider del repositorio social
// ---------------------------------------------------------------------------

/// Proveedor del repositorio social, inyectando el cliente Supabase real.
final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Providers de lectura
// ---------------------------------------------------------------------------

/// Feed principal de publicaciones sociales.
///
/// Retorna las últimas 50 publicaciones con datos de usuario, conteos y
/// estado de like. Se invalida cuando se da like, comenta o publica.
final socialFeedProvider = FutureProvider<List<Publicacion>>((ref) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.obtenerFeed(limit: 50);
});

/// Comentarios de una actividad específica.
///
/// Family parameter: [actividadId].
final socialCommentsProvider =
    FutureProvider.family<List<Comentario>, String>((ref, actividadId) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.obtenerComentarios(actividadId);
});

/// Verifica si el usuario actual dio like a una actividad.
///
/// Family parameter: [actividadId].
final likeStateProvider =
    FutureProvider.family<bool, String>((ref, actividadId) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;

  final repo = ref.watch(socialRepositoryProvider);
  return repo.tieneLike(actividadId, user.id);
});

// ---------------------------------------------------------------------------
// Mutaciones (funciones auxiliares, no providers)
// ---------------------------------------------------------------------------

/// Alterna el like de una actividad: da like si no lo tiene, lo quita si sí.
///
/// Invalida [socialFeedProvider] y [likeStateProvider] para refrescar la UI.
Future<void> toggleLike(WidgetRef ref, String actividadId,
    {required bool isLiked}) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  final repo = ref.read(socialRepositoryProvider);

  if (isLiked) {
    await repo.quitarLike(actividadId, user.id);
  } else {
    await repo.darLike(actividadId, user.id);
  }

  ref.invalidate(socialFeedProvider);
  ref.invalidate(likeStateProvider(actividadId));
}

/// Crea una publicación en el feed social e invalida el provider del feed.
Future<void> publicarEnFeed(
  WidgetRef ref, {
  required String descripcion,
  String? urlImagen,
  String tipo = 'milestone_reached',
}) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  final repo = ref.read(socialRepositoryProvider);
  await repo.crearPublicacion(
    usuarioId: user.id,
    descripcion: descripcion,
    urlImagen: urlImagen,
    tipo: tipo,
  );

  ref.invalidate(socialFeedProvider);
}

/// Envía un comentario a una actividad y refresca los comentarios de esa
/// actividad y el contador en el feed.
Future<void> enviarComentario(
  WidgetRef ref, {
  required String actividadId,
  required String texto,
}) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  final repo = ref.read(socialRepositoryProvider);
  await repo.agregarComentario(
    actividadId: actividadId,
    usuarioId: user.id,
    texto: texto,
  );

  ref.invalidate(socialCommentsProvider(actividadId));
  ref.invalidate(socialFeedProvider);
}

/// Edita el texto de un comentario existente.
Future<void> editarComentarioMutation(
  WidgetRef ref, {
  required String comentarioId,
  required String actividadId,
  required String texto,
}) async {
  final repo = ref.read(socialRepositoryProvider);
  await repo.editarComentario(comentarioId, texto);

  ref.invalidate(socialCommentsProvider(actividadId));
}

/// Elimina un comentario (soft delete).
Future<void> eliminarComentarioMutation(
  WidgetRef ref, {
  required String comentarioId,
  required String actividadId,
}) async {
  final repo = ref.read(socialRepositoryProvider);
  await repo.eliminarComentario(comentarioId);

  ref.invalidate(socialCommentsProvider(actividadId));
  ref.invalidate(socialFeedProvider);
}
