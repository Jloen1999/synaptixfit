import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/training/session.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'training_dialogs.dart';
import 'training_labels.dart';

/// Sesión sin terminar (Rutinas e historial). La abandonada (más de 6 h abierta)
/// se termina con lo registrado (cuenta en su día) o se descarta; la que sigue
/// en curso se continúa. Las acciones las resuelve el bloc de cada pantalla.
class OpenSessionCard extends StatelessWidget {
  const OpenSessionCard({
    super.key,
    required this.open,
    required this.busy,
    required this.onFinish,
    required this.onDiscard,
    this.onContinue,
  });

  final OpenSession open;
  final bool busy;

  /// Terminar con lo registrado: minutos y esfuerzo pedidos al usuario.
  final void Function(SessionFigures figures) onFinish;
  final VoidCallback onDiscard;

  /// Solo para la que sigue en curso (abre la sesión en vivo).
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final session = open.session;
    final title = open.dayNumber != null
        ? dayTitle(l10n, open.dayNumber!, open.dayName)
        : l10n.trainingSessionFree;
    final started = DateFormat.MMMEd(
      l10n.localeName,
    ).add_Hm().format(session.startedAt);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                open.stale
                    ? Icons.pending_actions_rounded
                    : Icons.timelapse_rounded,
                color: open.stale
                    ? context.palette.warning
                    : context.colors.primary,
                size: TokensSize.iconS,
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleSmall),
                    Text(
                      [?open.routineName, started].join(' · '),
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    if (open.stale)
                      Text(
                        l10n.trainingStaleSessionHint,
                        style: context.textStyles.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: TokensSpacing.xs,
            overflowSpacing: TokensSpacing.xs,
            children: [
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await showConfirmDialog(
                          context,
                          title: l10n.trainingDiscardSessionTitle,
                          message: l10n.trainingDiscardSessionMessage,
                          confirmLabel: l10n.trainingDiscardSession,
                        );
                        if (ok) onDiscard();
                      },
                child: Text(l10n.trainingDiscardSession),
              ),
              if (open.stale || onContinue == null)
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final figures = await showSessionFiguresDialog(
                            context,
                            confirmLabel: l10n.trainingFinishWithLogged,
                            subtitle: title,
                          );
                          if (figures != null) onFinish(figures);
                        },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.trainingFinishWithLogged),
                )
              else
                FilledButton(
                  onPressed: busy ? null : onContinue,
                  child: Text(l10n.trainingContinueDay),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
