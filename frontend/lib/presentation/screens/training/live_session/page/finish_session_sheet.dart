import 'package:flutter/material.dart';

import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';

/// Hoja de «Terminar» la sesión: una pregunta corta (el esfuerzo) y
/// «Guardar». Terminar son dos toques: «Terminar» y «Guardar» (vocabulario,
/// sección 4). Si faltan series ([missing]) o no hay ninguna ([empty]) se dice
/// en una frase, sin otro diálogo. Devuelve el esfuerzo (1-10) o nulo.
Future<int?> showFinishSessionSheet(
  BuildContext context, {
  int missing = 0,
  bool empty = false,
}) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => FinishSessionSheet(missing: missing, empty: empty),
);

/// Contenido de [showFinishSessionSheet].
class FinishSessionSheet extends StatefulWidget {
  const FinishSessionSheet({
    super.key,
    required this.missing,
    required this.empty,
  });

  final int missing;
  final bool empty;

  @override
  State<FinishSessionSheet> createState() => _FinishSessionSheetState();
}

class _FinishSessionSheetState extends State<FinishSessionSheet> {
  int _effort = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final note = widget.empty
        ? l10n.trainingFinishEmpty
        : widget.missing > 0
        ? l10n.trainingFinishMissing(widget.missing)
        : null;
    return SingleChildScrollView(
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
          Semantics(
            header: true,
            child: Text(
              l10n.commonEffortTitle,
              style: context.textStyles.titleLarge,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(
              note,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.l),
          AppEffortSlider(
            value: _effort,
            autofocus: true,
            onChanged: (v) => setState(() => _effort = v),
          ),
          const SizedBox(height: TokensSpacing.l),
          AppPrimaryButton(
            label: l10n.commonSave,
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(_effort),
          ),
        ],
      ),
    );
  }
}
