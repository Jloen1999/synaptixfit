import '../models/progress/badge.dart';
import '../models/progress/community_post_preview.dart';
import '../models/progress/physical_load.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Datos de otros dominios que muestra la pestaña Progreso: carga física
/// (`/api/v1/insights/physical-load`) y muro social (`/api/v1/social/posts`).
abstract interface class ProgressRepositoryContract {
  Future<AppResult<PhysicalLoad>> getPhysicalLoad();

  /// Últimas [size] publicaciones del muro.
  Future<AppResult<List<CommunityPostPreview>>> getCommunityPreview({
    int size = 3,
  });

  /// Publica en el muro un logro (insignia obtenida) con un comentario opcional.
  Future<AppResult<Unit>> shareBadge({required Badge badge, String? message});
}
