import 'package:flutter/material.dart';

import '../../../../domain/models/training/recommendation.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'metric_chips.dart';
import 'training_labels.dart';

/// Sugerencia de entrenamiento con acciones aplicar / descartar. Plegada
/// enseña los primeros ajustes; desplegada («Ver detalle» o un toque en la
/// tarjeta), el porqué y todos los ajustes, para revisarlos antes de aplicar.
class RecommendationCard extends StatefulWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.busy,
    required this.onApply,
    required this.onDiscard,
    this.initiallyExpanded = false,
  });

  final Recommendation recommendation;
  final bool busy;
  final VoidCallback onApply;
  final VoidCallback onDiscard;

  /// Empieza desplegada (p. ej. al terminar una sesión, donde la sugerencia
  /// es lo principal). En listas empieza plegada para que pese menos.
  final bool initiallyExpanded;

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  static const _visibleAdjustments = 2;

  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final r = widget.recommendation;
    final reason = r.description?.trim() ?? '';
    // Solo se puede desplegar si hay algo más que ver.
    final expandable =
        reason.isNotEmpty ||
        r.adjustments.length > _visibleAdjustments ||
        r.adjustments.any((a) => a.reason?.trim().isNotEmpty ?? false);
    final expanded = _expanded || !expandable;
    final adjustments = expanded
        ? r.adjustments
        : r.adjustments.take(_visibleAdjustments);
    final hidden = r.adjustments.length - adjustments.length;
    final muted = context.textStyles.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    final content = Padding(
      padding: const EdgeInsets.all(TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                r.type.icon,
                color: context.colors.secondary,
                size: TokensSize.iconS,
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(
                  r.type.label(l10n),
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.secondary,
                  ),
                ),
              ),
              if (r.applied)
                AppPill(
                  icon: Icons.check_rounded,
                  label: l10n.trainingRecommendationApplied,
                  color: context.palette.success,
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(r.title, style: context.textStyles.titleSmall),
          if (expanded && reason.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.xxs),
            Text(
              reason,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          for (final a in adjustments) ...[
            const SizedBox(height: TokensSpacing.s),
            if (a.exerciseName != null)
              Text(a.exerciseName!, style: context.textStyles.labelLarge),
            const SizedBox(height: TokensSpacing.xxs),
            ExerciseParameterChips(parameters: a.parameters),
            if (expanded && (a.reason?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: TokensSpacing.xxs),
              Text(a.reason!.trim(), style: muted),
            ],
          ],
          if (hidden > 0) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.trainingRecommendationMoreExercises(hidden),
              style: muted,
            ),
          ],
        ],
      ),
    );

    final actions = r.applied
        ? null
        // OverflowBar apila los botones si no caben (texto al 200 %).
        : OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: TokensSpacing.s,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              TextButton(
                onPressed: widget.busy ? null : widget.onDiscard,
                child: Text(l10n.trainingDiscard),
              ),
              AppPrimaryButton(
                label: l10n.trainingApply,
                loading: widget.busy,
                onPressed: widget.onApply,
              ),
            ],
          );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: context.motion(TokensDuration.normal),
            alignment: Alignment.topCenter,
            child: expandable
                // Toda la tarjeta despliega con el dedo o el ratón; para el
                // teclado y el lector la única parada es «Ver detalle», que
                // anuncia si está desplegada (sin una segunda parada igual).
                ? InkWell(
                    onTap: _toggle,
                    canRequestFocus: false,
                    excludeFromSemantics: true,
                    child: content,
                  )
                : content,
          ),
          if (expandable || actions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.s,
                0,
                TokensSpacing.s,
                TokensSpacing.s,
              ),
              child: Wrap(
                alignment: expandable
                    ? WrapAlignment.spaceBetween
                    : WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: TokensSpacing.xs,
                children: [
                  if (expandable)
                    MergeSemantics(
                      child: Semantics(
                        expanded: _expanded,
                        child: TextButton.icon(
                          onPressed: _toggle,
                          icon: Icon(
                            _expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                          label: Text(
                            _expanded
                                ? l10n.trainingRecommendationsLess
                                : l10n.trainingRecommendationDetail,
                          ),
                        ),
                      ),
                    ),
                  ?actions,
                ],
              ),
            ),
        ],
      ),
    );
  }
}
