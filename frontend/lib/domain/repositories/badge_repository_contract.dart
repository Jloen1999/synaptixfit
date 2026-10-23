import '../enums/badge_category.dart';
import '../models/progress/badge.dart';
import '../models/progress/streak.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Insignias y racha del usuario autenticado (`/api/v1/badges`, `/api/v1/streak`).
abstract interface class BadgeRepositoryContract {
  /// Catálogo completo con el progreso del usuario; [category] lo filtra.
  Future<AppResult<List<Badge>>> getCatalog({BadgeCategory? category});

  /// Insignias obtenidas; con [includeHidden] incluye las ocultas del perfil.
  Future<AppResult<List<Badge>>> getMine({bool includeHidden = false});

  /// Muestra u oculta en el perfil una insignia obtenida.
  Future<AppResult<Badge>> changeVisibility({
    required String badgeId,
    required bool visible,
  });

  /// Insignias obtenidas que aún no se han celebrado. Las otorga el servidor
  /// al procesar cada acción; el cliente no las evalúa.
  Future<AppResult<List<Badge>>> getUnnotified();

  /// Marca como celebradas las insignias [badgeIds].
  Future<AppResult<Unit>> markNotified(List<String> badgeIds);

  Future<AppResult<Streak>> getStreak();
}
