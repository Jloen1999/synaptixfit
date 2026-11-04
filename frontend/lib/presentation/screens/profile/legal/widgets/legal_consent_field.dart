import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/enums/legal_document_kind.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../profile_routes.dart';

/// Enlaces a la política de privacidad y a las condiciones. El registro, la
/// pantalla de aceptación y Ajustes los usan igual.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.onOpen});

  /// Por defecto abre el texto encima (con o sin sesión).
  final ValueChanged<LegalDocumentKind>? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final open = onOpen ?? (kind) => context.push(ProfilePaths.legal(kind));
    return Wrap(
      spacing: TokensSpacing.s,
      runSpacing: TokensSpacing.xs,
      children: [
        TextButton.icon(
          onPressed: () => open(LegalDocumentKind.privacy),
          icon: const Icon(Icons.privacy_tip_outlined),
          label: Text(l10n.profileLegalReadPrivacy),
        ),
        TextButton.icon(
          onPressed: () => open(LegalDocumentKind.terms),
          icon: const Icon(Icons.description_outlined),
          label: Text(l10n.profileLegalReadTerms),
        ),
      ],
    );
  }
}

/// Primero los enlaces y después la casilla obligatoria «He leído y acepto…»,
/// en el mismo orden en el registro y en la pantalla de aceptación. Sin
/// marcarla, el botón explica junto a ella por qué no sigue.
class LegalConsentField extends StatelessWidget {
  const LegalConsentField({
    super.key,
    this.enabled = true,
    this.autofocus = false,
    this.requiredMessage,
  });

  final bool enabled;
  final bool autofocus;

  /// Lo que se dice si se intenta seguir sin marcarla (por defecto, el del
  /// registro: «… para crear tu cuenta»).
  final String? requiredMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const LegalLinks(),
        AppConsentCheckbox(
          label: l10n.profileLegalCheckbox,
          requiredMessage: requiredMessage ?? l10n.registerLegalRequired,
          enabled: enabled,
          autofocus: autofocus,
        ),
      ],
    );
  }
}
