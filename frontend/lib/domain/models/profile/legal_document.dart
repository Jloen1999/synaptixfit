import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/legal_document_kind.dart';

part 'legal_document.freezed.dart';

/// Tipo de trozo de un texto legal.
enum LegalBlockType { heading, paragraph, bullet }

/// Un trozo de un texto legal: título de sección, párrafo o punto de lista.
@freezed
abstract class LegalBlock with _$LegalBlock {
  const factory LegalBlock({
    required LegalBlockType type,
    required String text,
  }) = _LegalBlock;
}

/// Política de privacidad, condiciones o borrado de cuenta, tal como la
/// publica el servidor (el mismo texto que la web pública). [contactConfigured]
/// es falso si el responsable o el correo aún están «pendientes».
@freezed
abstract class LegalDocument with _$LegalDocument {
  const factory LegalDocument({
    required LegalDocumentKind kind,
    required String language,
    required String version,
    required String title,
    required List<LegalBlock> blocks,
    @Default(true) bool contactConfigured,
  }) = _LegalDocument;
}

/// Si hay que aceptar la versión vigente de la política y las condiciones.
@freezed
abstract class LegalAcceptance with _$LegalAcceptance {
  const factory LegalAcceptance({
    required String currentVersion,
    String? acceptedVersion,
    DateTime? acceptedAt,
    required bool mustAccept,
  }) = _LegalAcceptance;
}
