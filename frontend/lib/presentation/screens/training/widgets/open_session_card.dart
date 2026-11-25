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
    // Foto del día de fondo y el texto abajo (ADR 0042): el estado en una
    // pastilla sólida, el nombre y cuándo empezó. Sin toque en toda la
    // tarjeta: lleva sus propios botones (nada de controles anidados).
    return AppCoverCard(
      layout: AppCoverLayout.bottom,
      imageUrl: open.coverImageUrl,
      padding: const EdgeInsets.all(TokensSpacing.m),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (open.stale)
            Padding(
              padding: const EdgeInsets.only(top: TokensSpacing.s),
              child: Text(
                l10n.trainingStaleSessionHint,
                style: context.textStyles.bodySmall,
              ),
            ),
          const SizedBox(height: TokensSpacing.s),
          // Descartar (no guarda) a un lado y Terminar o Continuar al otro:
          // separados para no pulsar uno por otro (vocabulario §4). Con texto
          // grande pasan a dos líneas en el mismo orden.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: TokensSpacing.l,
            runSpacing: TokensSpacing.xs,
            children: [
              // Descartar no guarda: en rojo, como en la hoja de salir de la
              // sesión (un color por verbo, vocabulario §4).
              AppDangerButton(
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
                label: l10n.trainingDiscardSession,
              ),
              // Sin destacar: en Gimnasio la acción principal es «Empezar».
              if (open.stale || onContinue == null)
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final figures = await showSessionFiguresDialog(
                            context,
                            confirmLabel: l10n.commonSave,
                            subtitle: title,
                          );
                          if (figures != null) onFinish(figures);
                        },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.trainingFinishAction),
                )
              else
                OutlinedButton(
                  onPressed: busy ? null : onContinue,
                  child: Text(l10n.trainingContinueDay),
                ),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCoverPill(
            icon: open.stale
                ? Icons.pending_actions_rounded
                : AppIcons.inProgress,
            color: open.stale
                ? context.palette.warning
                : context.colors.primary,
            label: open.stale
                ? l10n.trainingUnfinishedTitle
                : l10n.trainingProgressInProgress,
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            title,
            style: context.textStyles.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            [?open.routineName, started].join(' · '),
            style: context.textStyles.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
