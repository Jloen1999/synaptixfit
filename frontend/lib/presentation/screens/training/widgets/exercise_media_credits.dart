import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/models/training/media_credit.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Quién hizo la foto y el vídeo del ejercicio (ADR 0056), en una sola línea
/// discreta bajo la demostración («Foto: Everkinetic (wger) · Vídeo: wger»):
/// un solo toque, sin jerga de licencias. Al tocarla, la hoja «Créditos» lo
/// explica y enlaza cada licencia y cada obra, avisando de que se abren en el
/// navegador.
class ExerciseMediaCredits extends StatelessWidget {
  const ExerciseMediaCredits({super.key, required this.credits});

  final List<MediaCredit> credits;

  @override
  Widget build(BuildContext context) {
    if (credits.isEmpty) return const SizedBox.shrink();
    final l10n = context.localizations;
    final line = credits.map((c) => _kindLabel(l10n, c)).join(' · ');
    return Semantics(
      button: true,
      label: l10n.trainingMediaCreditsSpoken(line),
      onTap: () => _showCredits(context, credits),
      onTapHint: l10n.trainingMediaCreditsOpen,
      excludeSemantics: true,
      child: AppFocusOutline(
        child: InkWell(
          onTap: () => _showCredits(context, credits),
          borderRadius: BorderRadius.circular(TokensRadius.s),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TokensLayout.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: TokensSpacing.s),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      line,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: TokensSpacing.xs),
                  Icon(
                    AppIcons.info,
                    size: TokensSize.iconXs,
                    color: context.colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// «Foto: Everkinetic (wger)» o «Vídeo: wger».
String _kindLabel(AppLocalizations l10n, MediaCredit c) {
  final author = c.author?.trim();
  final who = author == null || author.isEmpty || author == c.source
      ? c.source
      : '$author (${c.source})';
  return switch (c.kind) {
    MediaCreditKind.photo => l10n.trainingMediaCreditPhoto(who),
    MediaCreditKind.video => l10n.trainingMediaCreditVideo(who),
  };
}

Future<void> _showCredits(BuildContext context, List<MediaCredit> credits) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => _CreditsSheet(credits: credits),
    );

class _CreditsSheet extends StatelessWidget {
  const _CreditsSheet({required this.credits});

  final List<MediaCredit> credits;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.l,
          0,
          TokensSpacing.l,
          TokensSpacing.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.trainingMediaCreditsTitle,
                style: context.textStyles.titleLarge,
              ),
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.trainingMediaCreditsIntro,
              style: context.textStyles.bodyMedium,
            ),
            for (final c in credits) ...[
              const SizedBox(height: TokensSpacing.m),
              Text(_kindLabel(l10n, c), style: context.textStyles.titleSmall),
              Text(
                l10n.trainingMediaCreditLicense(c.license),
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              Wrap(
                spacing: TokensSpacing.s,
                children: [
                  _ExternalLink(
                    label: l10n.trainingMediaCreditSeeLicense,
                    url: c.licenseUrl,
                  ),
                  if (c.workUrl case final work?)
                    _ExternalLink(
                      label: l10n.trainingMediaCreditSeeWork,
                      url: work,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Enlace que sale de la app: lo dice el icono y el lector («se abre en el
/// navegador»). Solo abre direcciones https; si no se puede, lo avisa.
class _ExternalLink extends StatelessWidget {
  const _ExternalLink({required this.label, required this.url});

  final String label;
  final String url;

  Future<void> _open(BuildContext context) async {
    final l10n = context.localizations;
    final uri = Uri.tryParse(url);
    var ok = false;
    if (uri != null && uri.scheme == 'https') {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Exception {
        ok = false;
      }
    }
    if (!ok && context.mounted) {
      context.showSnack(l10n.trainingMediaCreditOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // Un solo nodo para el lector: el botón, marcado como enlace y con el
    // aviso de que sale de la app.
    return MergeSemantics(
      child: Semantics(
        link: true,
        hint: l10n.trainingMediaCreditsOpensBrowser,
        child: TextButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(AppIcons.openExternal),
          label: Text(label),
          iconAlignment: IconAlignment.end,
        ),
      ),
    );
  }
}
