import 'package:freezed_annotation/freezed_annotation.dart';

part 'lockdown_status.freezed.dart';

/// Estado del bloqueo global de la plataforma.
@freezed
abstract class LockdownStatus with _$LockdownStatus {
  const factory LockdownStatus({
    required bool active,
    DateTime? startedAt,
    String? startedBy,
    DateTime? updatedAt,
  }) = _LockdownStatus;
}
