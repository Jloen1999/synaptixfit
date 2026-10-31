import 'study_by_subject.dart';
import 'study_week.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../account/account.dart';
import 'badge.dart';
import 'community_post_preview.dart';
import 'physical_load.dart';
import 'streak.dart';
import 'weekly_analytics.dart';

part 'progress_overview.freezed.dart';

/// Datos de la pestaña Progreso.
///
/// Las secciones secundarias ([weekly], [physicalLoad], [communityPosts]) son
/// nulas si no se pudieron cargar: la pestaña se muestra igualmente.
@freezed
abstract class ProgressOverview with _$ProgressOverview {
  const factory ProgressOverview({
    required Account account,
    required Streak streak,
    required List<Badge> earnedBadges,
    WeeklyAnalytics? weekly,
    PhysicalLoad? physicalLoad,
    List<CommunityPostPreview>? communityPosts,

    /// «Tu estudio» de la semana (nulo si no se pudo cargar).
    StudyWeek? studyWeek,

    /// Estudio por asignatura (últimas 4 semanas); opcional.
    StudyBySubject? studyBySubject,
  }) = _ProgressOverview;
}
