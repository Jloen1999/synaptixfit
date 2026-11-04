import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/legal_document_kind.dart';
import '../../../../../domain/models/profile/legal_document.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/legal_document_bloc.dart';

/// Política de privacidad, condiciones de uso o cómo borrar la cuenta
/// (`/legal/:document`). Se abre con o sin sesión (desde el registro) y enseña
/// el mismo texto que la web pública.
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.kind});

  final LegalDocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) =>
          getIt<LegalDocumentBloc>()
            ..add(LegalDocumentEvent.started(kind: kind, language: language)),
      child: _LegalDocumentView(kind: kind, language: language),
    );
  }
}

class _LegalDocumentView extends StatelessWidget {
  const _LegalDocumentView({required this.kind, required this.language});

  final LegalDocumentKind kind;
  final String language;

  String _fallbackTitle(BuildContext context) {
    final l10n = context.localizations;
    return switch (kind) {
      LegalDocumentKind.privacy => l10n.profileLegalPrivacy,
      LegalDocumentKind.terms => l10n.profileLegalTerms,
      LegalDocumentKind.accountDeletion => l10n.profileLegalAccountDeletion,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LegalDocumentBloc, LegalDocumentState>(
      builder: (context, state) {
        final document = state.document;
        return Scaffold(
          appBar: AppPageBar.reading(
            title: Text(document?.title ?? _fallbackTitle(context)),
          ),
          body: switch (state) {
            LegalDocumentState(loading: true) => const AppSkeletonList(
              height: TokensSize.guideSkeleton,
            ),
            LegalDocumentState(:final error?) => AppErrorView(
              error: error,
              onRetry: () => context.read<LegalDocumentBloc>().add(
                LegalDocumentEvent.started(kind: kind, language: language),
              ),
            ),
            LegalDocumentState(:final document?) => _LegalBody(
              document: document,
              language: language,
            ),
            _ => AppEmptyState(
              icon: Icons.description_outlined,
              title: context.localizations.profileErrorLegalNotFound,
              action: AppSecondaryButton(
                label: context.localizations.commonRetry,
                onPressed: () => context.read<LegalDocumentBloc>().add(
                  LegalDocumentEvent.started(kind: kind, language: language),
                ),
              ),
            ),
          },
        );
      },
    );
  }
}

class _LegalBody extends StatelessWidget {
  const _LegalBody({required this.document, required this.language});

  final LegalDocument document;

  /// Idioma de la app: si el texto llega en otro, se avisa.
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final date = DateTime.tryParse(document.version);
    final version = date == null
        ? document.version
        : DateFormat.yMMMMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(date);
    return SelectionArea(
      child: ProfileScrollBody(
        children: [
          Text(
            l10n.profileLegalVersion(version),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (document.language != language) ...[
            const SizedBox(height: TokensSpacing.s),
            AppInlineMessage(message: l10n.profileLegalLanguageNote),
          ],
          const SizedBox(height: TokensSpacing.m),
          for (final block in document.blocks) _LegalBlockView(block: block),
          const SizedBox(height: TokensSpacing.xl),
        ],
      ),
    );
  }
}

class _LegalBlockView extends StatelessWidget {
  const _LegalBlockView({required this.block});

  final LegalBlock block;

  @override
  Widget build(BuildContext context) {
    return switch (block.type) {
      LegalBlockType.heading => Padding(
        padding: const EdgeInsets.only(
          top: TokensSpacing.l,
          bottom: TokensSpacing.s,
        ),
        child: Semantics(
          header: true,
          child: Text(block.text, style: context.textStyles.titleMedium),
        ),
      ),
      LegalBlockType.paragraph => Padding(
        padding: const EdgeInsets.only(bottom: TokensSpacing.s),
        child: _LinkedText(block.text),
      ),
      LegalBlockType.bullet => Padding(
        padding: const EdgeInsets.only(
          left: TokensSpacing.s,
          bottom: TokensSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Un carácter, no un icono: escala con el texto grande y queda
            // alineado con la primera línea.
            ExcludeSemantics(
              child: Text(
                '•  ',
                style: context.textStyles.bodyLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: _LinkedText(block.text)),
          ],
        ),
      ),
    };
  }
}

/// Párrafo con las direcciones web y los correos pulsables (abren el
/// navegador o el correo). El resto es texto normal y seleccionable.
class _LinkedText extends StatefulWidget {
  const _LinkedText(this.text);

  final String text;

  @override
  State<_LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<_LinkedText> {
  static final _links = RegExp(
    r'(https://[\w.\-/?=&%#]+[\w/])|([\w.+\-]+@[\w\-]+(?:\.[\w\-]+)+)',
  );
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _links.allMatches(widget.text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: widget.text.substring(last, match.start)));
      }
      final found = match.group(0)!;
      final uri = match.group(1) != null
          ? Uri.parse(found)
          : Uri(scheme: 'mailto', path: found);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => launchUrl(uri, mode: LaunchMode.externalApplication);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: found,
          recognizer: recognizer,
          style: context.textStyles.bodyLarge?.copyWith(
            color: context.colors.secondary,
            decoration: TextDecoration.underline,
          ),
        ),
      );
      last = match.end;
    }
    if (last < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(last)));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: context.textStyles.bodyLarge,
    );
  }
}
