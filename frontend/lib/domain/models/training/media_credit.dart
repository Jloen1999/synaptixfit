import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_credit.freezed.dart';

/// Si el crédito es de la foto o del vídeo del ejercicio.
enum MediaCreditKind { photo, video }

/// Quién hizo la foto o el vídeo de un ejercicio y con qué licencia (ADR
/// 0056). Solo lo tienen los medios tomados de fuentes abiertas; la ficha lo
/// enseña porque esas licencias piden atribución.
@freezed
abstract class MediaCredit with _$MediaCredit {
  const factory MediaCredit({
    required MediaCreditKind kind,
    required String source,
    required String license,
    required String licenseUrl,
    String? author,
    String? workUrl,
  }) = _MediaCredit;
}
