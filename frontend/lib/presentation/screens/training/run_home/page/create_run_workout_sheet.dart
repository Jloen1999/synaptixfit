import 'package:flutter/material.dart';

import '../../../../../domain/models/training/run.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/run_labels.dart';

/// Hoja «Crear entreno guiado»: una plantilla del servidor o desde cero. La
/// comparten «Deportes» y «Correr, andar o bici». Devuelve el código de la
/// plantilla, cadena vacía para «desde cero» o nulo si se cerró sin elegir.
Future<String?> showCreateRunWorkoutSheet(
  BuildContext context,
  List<RunWorkout> templates,
) {
  final l10n = context.localizations;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: TokensSpacing.m),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.l),
            child: Semantics(
              header: true,
              child: Text(
                l10n.runCreateWorkoutTitle,
                style: sheet.textStyles.titleLarge,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.l,
              TokensSpacing.xs,
              TokensSpacing.l,
              TokensSpacing.s,
            ),
            child: Text(l10n.runCreateWorkoutIntro),
          ),
          for (final t in templates)
            AppFocusOutline(
              child: ListTile(
                leading: Icon(
                  Icons.directions_run_rounded,
                  color: sheet.colors.secondary,
                ),
                title: Text(RunLabels.templateName(l10n, t.templateCode)),
                subtitle: Text(
                  [
                    RunLabels.templateWhy(l10n, t.templateCode),
                    t.groups.map((g) => RunLabels.group(l10n, g)).join(' · '),
                  ].join('\n'),
                ),
                isThreeLine: true,
                onTap: () => Navigator.of(sheet).pop(t.templateCode),
              ),
            ),
          AppFocusOutline(
            child: ListTile(
              leading: Icon(
                Icons.edit_note_rounded,
                color: sheet.colors.secondary,
              ),
              title: Text(l10n.runCreateFromScratch),
              subtitle: Text(l10n.runCreateFromScratchHint),
              onTap: () => Navigator.of(sheet).pop(''),
            ),
          ),
        ],
      ),
    ),
  );
}
