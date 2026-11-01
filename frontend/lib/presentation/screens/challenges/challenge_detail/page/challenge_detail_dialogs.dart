import 'package:flutter/material.dart' hide Visibility;

import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/challenge_labels.dart';

/// Confirmación de borrado avisando de la XP que se restará.
Future<bool> showDeleteChallengeDialog(
  BuildContext context,
  int xpAwarded,
) async {
  final l10n = context.localizations;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.delete_outline_rounded),
      title: Text(l10n.challengesDeleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.challengesDeleteMessage),
          if (xpAwarded > 0) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              l10n.challengesDeleteXpWarning(xpAwarded),
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Foco inicial en Cancelar: un Enter accidental no borra nada.
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Confirmación antes de descompletar un reto (resta su XP).
Future<bool> showUncompleteDialog(BuildContext context) async {
  final l10n = context.localizations;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.challengesUncompleteTitle),
      content: Text(l10n.challengesUncompleteMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.commonConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Elige la visibilidad del reto.
Future<Visibility?> showVisibilityDialog(
  BuildContext context,
  Visibility current,
) {
  final l10n = context.localizations;
  return showDialog<Visibility>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.challengesDetailVisibility),
      children: [
        for (final v in Visibility.values)
          AppFocusOutline(
            child: ListTile(
              leading: Icon(v.challengeIcon),
              title: Text(v.challengeLabel(context)),
              trailing: v == current
                  ? Icon(Icons.check_rounded, color: context.colors.primary)
                  : null,
              selected: v == current,
              onTap: () => Navigator.pop(context, v),
            ),
          ),
      ],
    ),
  );
}

/// Progreso manual elegido en el diálogo: el valor absoluto («llevas 60 %»).
class RecordProgressInput {
  const RecordProgressInput({required this.value});

  final double value;
}

/// Diálogo «¿Cuánto llevas?» de un reto sin tareas: muestra el progreso
/// actual y fija el nuevo valor (no suma). Con tareas no se usa: las tareas son
/// de sí o no.
Future<RecordProgressInput?> showRecordProgressDialog(
  BuildContext context,
  Challenge challenge,
) {
  final l10n = context.localizations;
  final current = challenge.progress.roundToDouble().clamp(0, 99).toDouble();
  var value = current;
  return showDialog<RecordProgressInput>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        // Con el texto al 200 % o en horizontal, el contenido se desplaza.
        scrollable: true,
        title: Text(l10n.challengesProgressHowMuch),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.challengesProgressCurrent(current.round()),
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TokensSpacing.s),
            // La cifra grande es visual: el deslizador ya anuncia el valor.
            ExcludeSemantics(
              child: Text(
                l10n.challengesProgressPercent(value.round()),
                style: context.textStyles.headlineSmall,
              ),
            ),
            Slider(
              value: value,
              max: 100,
              divisions: 20,
              label: l10n.challengesProgressPercent(value.round()),
              semanticFormatterCallback: (v) =>
                  l10n.challengesProgressPercent(v.round()),
              onChanged: (v) => setState(() => value = v),
            ),
            if (value >= 100)
              Text(
                l10n.challengesProgressWillComplete,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: value == current
                ? null
                : () => Navigator.pop(
                    context,
                    RecordProgressInput(value: value.roundToDouble()),
                  ),
            child: Text(l10n.challengesProgressAction),
          ),
        ],
      ),
    ),
  );
}

/// Hoja para reordenar las tareas con botones subir/bajar. Devuelve los ids.
Future<List<String>?> showReorderMilestonesSheet(
  BuildContext context,
  List<Milestone> milestones,
) {
  final l10n = context.localizations;
  final order = [...milestones];
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void move(int index, int delta) => setState(() {
          final item = order.removeAt(index);
          order.insert(index + delta, item);
        });
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.l,
            0,
            TokensSpacing.l,
            TokensSpacing.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.challengesReorderTitle,
                style: context.textStyles.titleLarge,
              ),
              const SizedBox(height: TokensSpacing.m),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < order.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text(
                            '${i + 1}',
                            style: context.textStyles.labelMedium,
                          ),
                        ),
                        title: Text(order[i].title),
                        subtitle: Text(order[i].status.label(context)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.challengesMoveUp,
                              onPressed: i == 0 ? null : () => move(i, -1),
                              icon: const Icon(Icons.arrow_upward_rounded),
                            ),
                            IconButton(
                              tooltip: l10n.challengesMoveDown,
                              onPressed: i == order.length - 1
                                  ? null
                                  : () => move(i, 1),
                              icon: const Icon(Icons.arrow_downward_rounded),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, order.map((m) => m.id).toList()),
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        );
      },
    ),
  );
}
