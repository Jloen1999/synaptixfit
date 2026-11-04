import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/challenge_link_type.dart';

part 'challenge_references.freezed.dart';

/// Asignatura seleccionable en un reto.
@freezed
abstract class ChallengeSubjectOption with _$ChallengeSubjectOption {
  const factory ChallengeSubjectOption({
    required String id,
    required String name,
    String? code,
  }) = _ChallengeSubjectOption;
}

/// Apunte que se puede adjuntar a una tarea.
@freezed
abstract class ChallengeNoteOption with _$ChallengeNoteOption {
  const factory ChallengeNoteOption({
    required String id,
    required String title,
    String? subjectId,
  }) = _ChallengeNoteOption;
}

/// Archivo de asignatura que se puede adjuntar a una tarea.
@freezed
abstract class ChallengeFileOption with _$ChallengeFileOption {
  const factory ChallengeFileOption({
    required String id,
    required String fileName,
    String? mimeType,
    String? subjectId,
  }) = _ChallengeFileOption;
}

/// Material adjuntable de una asignatura.
@freezed
abstract class ChallengeAttachmentOptions with _$ChallengeAttachmentOptions {
  const factory ChallengeAttachmentOptions({
    @Default(<ChallengeNoteOption>[]) List<ChallengeNoteOption> notes,
    @Default(<ChallengeFileOption>[]) List<ChallengeFileOption> files,
  }) = _ChallengeAttachmentOptions;
}

/// Entrega, examen o bloque al que se puede vincular un reto o tarea.
@freezed
abstract class ChallengeLinkOption with _$ChallengeLinkOption {
  const factory ChallengeLinkOption({
    required String id,
    required ChallengeLinkType type,
    required String title,

    /// Cuándo vence la entrega; nulo en un día de rutina.
    DateTime? at,
    String? subjectId,

    /// Día de rutina: semana y día de la semana (1 = lunes).
    int? weekNumber,
    int? dayNumber,
  }) = _ChallengeLinkOption;
}
