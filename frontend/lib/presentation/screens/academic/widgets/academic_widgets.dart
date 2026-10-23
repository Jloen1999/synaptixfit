import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../domain/models/account/account.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../../auth/session/bloc/session_bloc.dart';

/// Ancho máximo del contenido en pantallas grandes.
const academicMaxWidth = TokensLayout.contentMaxWidth;

/// Centra y limita el ancho del contenido de una pantalla.
class AcademicBody extends StatelessWidget {
  const AcademicBody({
    super.key,
    required this.child,
    this.maxWidth = academicMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) =>
      AppContentWidth(maxWidth: maxWidth, child: child);
}

/// Pide confirmación antes de una acción destructiva.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final l10n = context.localizations;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        // Foco inicial en Cancelar: un Enter accidental no borra nada.
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel ?? l10n.commonDelete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Propaga la cuenta actualizada (nivel y XP) a toda la app.
void syncSessionAccount(BuildContext context, Account account) =>
    context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));

/// Markdown con la tipografía del tema.
class AcademicMarkdown extends StatelessWidget {
  const AcademicMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
  });

  final String data;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: context.textStyles.bodyLarge,
        h1: context.textStyles.headlineSmall,
        h2: context.textStyles.titleLarge,
        h3: context.textStyles.titleMedium,
        blockquoteDecoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(TokensRadius.s),
          border: Border(
            left: BorderSide(color: context.colors.tertiary, width: 3),
          ),
        ),
        codeblockDecoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(TokensRadius.s),
        ),
      ),
    );
  }
}

/// Barra de progreso fina con el color indicado.
class AcademicProgressBar extends StatelessWidget {
  const AcademicProgressBar({
    super.key,
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(TokensRadius.pill),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1).toDouble(),
      color: color,
      backgroundColor: color.withValues(alpha: 0.16),
    ),
  );
}
