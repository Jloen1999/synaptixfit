import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/admin/admin_audit_action.dart';
import '../../enums/admin/admin_audit_entity.dart';
import '../../enums/admin/admin_exercise_difficulty.dart';
import '../../enums/admin/admin_exercise_modality.dart';
import '../../enums/admin/admin_sort_direction.dart';
import '../../enums/admin/admin_user_sort.dart';
import '../../enums/admin/admin_user_status.dart';
import '../../enums/user_role.dart';

part 'admin_queries.freezed.dart';

/// Filtros del buscador de usuarios. Los valores nulos no filtran.
@freezed
abstract class AdminUserQuery with _$AdminUserQuery {
  const factory AdminUserQuery({
    @Default('') String text,
    UserRole? role,
    bool? shadowbanned,
    @Default(AdminUserStatus.active) AdminUserStatus status,
    int? minLevel,
    int? maxLevel,
    @Default(AdminUserSort.createdAt) AdminUserSort sort,
    @Default(AdminSortDirection.desc) AdminSortDirection direction,
  }) = _AdminUserQuery;
}

/// Filtros del registro de auditoría. Los valores nulos no filtran.
@freezed
abstract class AuditQuery with _$AuditQuery {
  const factory AuditQuery({
    AdminAuditAction? action,
    AdminAuditEntity? entityType,
    String? entityId,
    DateTime? from,
    DateTime? to,
  }) = _AuditQuery;
}

/// Filtros del buscador de ejercicios del panel.
@freezed
abstract class AdminExerciseQuery with _$AdminExerciseQuery {
  const factory AdminExerciseQuery({
    @Default('') String text,
    AdminExerciseDifficulty? difficulty,
    AdminExerciseModality? modality,
    @Default(true) bool includeInactive,
  }) = _AdminExerciseQuery;
}
