part of 'badges_bloc.dart';

enum BadgesStatus { loading, loaded, failure }

@freezed
abstract class BadgesState with _$BadgesState {
  const factory BadgesState({
    @Default(BadgesStatus.loading) BadgesStatus status,
    @Default(<Badge>[]) List<Badge> badges,

    /// Categoría seleccionada; `null` = todas.
    BadgeCategory? category,
    AppError? error,

    /// Insignias con una acción en curso.
    @Default(<String>{}) Set<String> busyIds,

    /// Resultado puntual de una acción (se limpia justo después de emitirse).
    BadgesFeedback? feedback,
  }) = _BadgesState;

  const BadgesState._();

  List<Badge> get filtered => category == null
      ? badges
      : badges.where((b) => b.category == category).toList();

  int get earnedCount => badges.where((b) => b.earned).length;

  Badge? byId(String id) {
    for (final b in badges) {
      if (b.id == id) return b;
    }
    return null;
  }
}

/// Aviso que la página muestra como SnackBar.
@freezed
sealed class BadgesFeedback with _$BadgesFeedback {
  const factory BadgesFeedback.visibilityChanged({required bool visible}) =
      BadgesVisibilityChanged;

  const factory BadgesFeedback.shared() = BadgesShared;

  const factory BadgesFeedback.failed(AppError error) = BadgesActionFailed;
}
