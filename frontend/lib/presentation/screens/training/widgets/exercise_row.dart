import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../domain/models/training/routine.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'exercise_thumbnail.dart';
import 'metric_chips.dart';

/// Ejercicio de un borrador de rutina con sus chips y, si es editable,
/// acciones con texto: subir/bajar (sin arrastrar, para no bloquear el
/// scroll), editar series, cambiar y quitar. Van en una fila propia debajo
/// para que el nombre tenga todo el ancho en un móvil estrecho.
class ExerciseRow extends StatefulWidget {
  const ExerciseRow({
    super.key,
    required this.name,
    required this.parameters,
    this.position,
    this.count,
    this.thumbnailUrl,
    this.met,
    this.bodyWeightKg,
    this.realDurationSeconds,
    this.inactive = false,
    this.onTap,
    this.onMoveUp,
    this.onMoveDown,
    this.onEdit,
    this.onReplace,
    this.onRemove,
  });

  final String name;
  final ExerciseParameters parameters;

  /// Posición (desde 1) y total del día: se anuncian al mover el ejercicio.
  final int? position;
  final int? count;
  final String? thumbnailUrl;
  final double? met;
  final double? bodyWeightKg;
  final int? realDurationSeconds;
  final bool inactive;
  final VoidCallback? onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onEdit;

  /// Cambiar por otro ejercicio del mismo músculo.
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;

  @override
  State<ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<ExerciseRow> {
  final _upFocus = FocusNode();
  final _downFocus = FocusNode();

  bool get _editable =>
      widget.onMoveUp != null ||
      widget.onMoveDown != null ||
      widget.onEdit != null ||
      widget.onReplace != null ||
      widget.onRemove != null;

  @override
  void didUpdateWidget(ExerciseRow old) {
    super.didUpdateWidget(old);
    // Al llegar arriba o abajo del todo su botón se desactiva: el foco pasa
    // al contrario en vez de perderse (WCAG 2.4.3).
    if (widget.onMoveUp == null && _upFocus.hasFocus) {
      _downFocus.requestFocus();
    } else if (widget.onMoveDown == null && _downFocus.hasFocus) {
      _upFocus.requestFocus();
    }
    final moved = widget.position != old.position;
    if (moved &&
        (_upFocus.hasFocus || _downFocus.hasFocus) &&
        widget.position != null &&
        widget.count != null) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.localizations.trainingExerciseMovedTo(
          widget.name,
          widget.position!,
          widget.count!,
        ),
        Directionality.of(context),
      );
    }
  }

  @override
  void dispose() {
    _upFocus.dispose();
    _downFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final name = widget.name;
    final info = AppFocusOutline(
      borderRadius: BorderRadius.circular(TokensRadius.m),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TokensSpacing.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExerciseThumbnail(
                url: widget.thumbnailUrl,
                size: TokensSize.thumbnailS,
              ),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: context.textStyles.titleSmall),
                    if (widget.inactive)
                      Padding(
                        padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                        child: AppPill(
                          icon: Icons.block_rounded,
                          label: l10n.trainingExerciseInactive,
                          color: context.palette.warning,
                        ),
                      ),
                    const SizedBox(height: TokensSpacing.xs),
                    ExerciseParameterChips(
                      parameters: widget.parameters,
                      met: widget.met,
                      bodyWeightKg: widget.bodyWeightKg,
                      realDurationSeconds: widget.realDurationSeconds,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!_editable) return info;
    // Acciones con texto y en la misma tarjeta que su ejercicio: no hay un
    // menú de tres puntos que obligue a adivinar a qué ejercicio se refiere.
    // Con letra grande bajan a otra fila (OverflowBar).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        info,
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.start,
          overflowSpacing: TokensSpacing.xs,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  focusNode: _upFocus,
                  tooltip: l10n.trainingMoveUpNamed(name),
                  onPressed: widget.onMoveUp,
                  icon: const Icon(AppIcons.moveUp),
                ),
                IconButton(
                  focusNode: _downFocus,
                  tooltip: l10n.trainingMoveDownNamed(name),
                  onPressed: widget.onMoveDown,
                  icon: const Icon(AppIcons.moveDown),
                ),
              ],
            ),
            Wrap(
              spacing: TokensSpacing.xs,
              children: [
                if (widget.onEdit != null)
                  _action(
                    widget.onEdit!,
                    AppIcons.filters,
                    l10n.trainingEditSetsShort,
                    l10n.trainingEditSetsNamed(name),
                  ),
                if (widget.onReplace != null)
                  _action(
                    widget.onReplace!,
                    Icons.swap_horiz_rounded,
                    l10n.trainingReplaceShort,
                    l10n.trainingReplaceExerciseNamed(name),
                  ),
                if (widget.onRemove != null)
                  _action(
                    widget.onRemove!,
                    AppIcons.delete,
                    l10n.trainingRemoveShort,
                    l10n.trainingRemoveExerciseNamed(name),
                    color: context.colors.error,
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Botón con texto corto visible y, para el lector, el nombre del ejercicio.
  Widget _action(
    VoidCallback onPressed,
    IconData icon,
    String label,
    String spoken, {
    Color? color,
  }) => Semantics(
    button: true,
    label: spoken,
    excludeSemantics: true,
    onTap: onPressed,
    child: TextButton.icon(
      style: color == null
          ? null
          : TextButton.styleFrom(foregroundColor: color),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    ),
  );
}
