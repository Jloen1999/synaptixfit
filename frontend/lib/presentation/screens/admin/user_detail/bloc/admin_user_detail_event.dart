part of 'admin_user_detail_bloc.dart';

@freezed
sealed class AdminUserDetailEvent with _$AdminUserDetailEvent {
  const factory AdminUserDetailEvent.started(String userId) =
      AdminUserDetailStarted;

  const factory AdminUserDetailEvent.refreshed() = AdminUserDetailRefreshed;

  const factory AdminUserDetailEvent.timelineMoreRequested() =
      AdminUserDetailTimelineMoreRequested;

  /// Los valores nulos no cambian.
  const factory AdminUserDetailEvent.identityUpdated({
    String? fullName,
    String? email,
  }) = AdminUserDetailIdentityUpdated;

  const factory AdminUserDetailEvent.progressSet({
    required int level,
    required int levelXp,
  }) = AdminUserDetailProgressSet;

  const factory AdminUserDetailEvent.roleChanged(UserRole role) =
      AdminUserDetailRoleChanged;

  const factory AdminUserDetailEvent.shadowbanChanged({
    required bool shadowbanned,
  }) = AdminUserDetailShadowbanChanged;

  const factory AdminUserDetailEvent.wipeRequested() =
      AdminUserDetailWipeRequested;

  const factory AdminUserDetailEvent.anonymizeRequested() =
      AdminUserDetailAnonymizeRequested;

  const factory AdminUserDetailEvent.deleteRequested() =
      AdminUserDetailDeleteRequested;

  const factory AdminUserDetailEvent.exportRequested() =
      AdminUserDetailExportRequested;
}
