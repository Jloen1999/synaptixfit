import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/challenge_status.dart';
import '../../enums/challenge_tasks_filter.dart';
import '../../enums/challenge_type.dart';

part 'challenge_query.freezed.dart';

/// Filtros del listado de retos propios. Los campos nulos no filtran.
@freezed
abstract class ChallengeQuery with _$ChallengeQuery {
  const factory ChallengeQuery({
    ChallengeStatus? status,
    ChallengeType? type,
    ChallengeTasksFilter? tasks,
    String? search,
  }) = _ChallengeQuery;

  const ChallengeQuery._();

  bool get isFiltered =>
      status != null ||
      type != null ||
      tasks != null ||
      (search?.trim().isNotEmpty ?? false);
}
