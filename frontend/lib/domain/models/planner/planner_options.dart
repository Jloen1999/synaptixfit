import 'package:freezed_annotation/freezed_annotation.dart';

part 'planner_options.freezed.dart';

/// Asignatura que se puede asociar a un bloque o entrega.
@freezed
abstract class SubjectOption with _$SubjectOption {
  const factory SubjectOption({
    required String id,
    required String name,
    String? code,
    String? icsUrl,
  }) = _SubjectOption;

  const SubjectOption._();

  bool get hasIcsUrl => icsUrl != null && icsUrl!.isNotEmpty;
}

/// Rutina que se puede distribuir o vincular.
@freezed
abstract class RoutineOption with _$RoutineOption {
  const factory RoutineOption({required String id, required String name}) =
      _RoutineOption;
}

/// Reto que se puede vincular a un bloque.
@freezed
abstract class ChallengeOption with _$ChallengeOption {
  const factory ChallengeOption({required String id, required String title}) =
      _ChallengeOption;
}
