import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../domain/models/training/routine.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'exercise_thumbnail.dart';
import 'metric_chips.dart';

/// Ejercicio de un día con sus chips y, si es editable, acciones para
/// subir/bajar (sin arrastrar, para no bloquear el scroll) y un menú con
/// editar, cambiar y quitar. Las acciones van en una fila propia debajo para
/// que el nombre tenga todo el ancho en un móvil estrecho con letra grande.
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

  bool get _hasMenu =>
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        info,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              focusNode: _upFocus,
              tooltip: l10n.trainingMoveUpNamed(name),
              onPressed: widget.onMoveUp,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
            IconButton(
              focusNode: _downFocus,
              tooltip: l10n.trainingMoveDownNamed(name),
              onPressed: widget.onMoveDown,
              icon: const Icon(Icons.arrow_downward_rounded),
            ),
            // Las acciones menos frecuentes van juntas en un menú: la fila
            // queda limpia y cada opción lleva su texto.
            if (_hasMenu)
              PopupMenuButton<VoidCallback>(
                tooltip: l10n.trainingExerciseMoreActions(name),
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) => action(),
                itemBuilder: (context) => [
                  if (widget.onEdit != null)
                    _menuItem(
                      context,
                      widget.onEdit!,
                      Icons.tune_rounded,
                      l10n.trainingEditParameters,
                    ),
                  if (widget.onReplace != null)
                    _menuItem(
                      context,
                      widget.onReplace!,
                      Icons.swap_horiz_rounded,
                      l10n.trainingReplaceExercise,
                    ),
                  if (widget.onRemove != null)
                    _menuItem(
                      context,
                      widget.onRemove!,
                      Icons.delete_outline_rounded,
                      l10n.trainingRemoveExercise,
                      color: context.colors.error,
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<VoidCallback> _menuItem(
    BuildContext context,
    VoidCallback action,
    IconData icon,
    String label, {
    Color? color,
  }) => PopupMenuItem(
    value: action,
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: TokensSpacing.m),
        Flexible(
          child: Text(
            label,
            style: color == null ? null : TextStyle(color: color),
          ),
        ),
      ],
    ),
  );
}
