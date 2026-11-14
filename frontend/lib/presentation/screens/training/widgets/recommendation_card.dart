import 'package:flutter/material.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/models/training/recommendation.dart';
import '../../../../domain/models/training/routine.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'metric_chips.dart';
import 'training_labels.dart';

/// Sugerencia de entrenamiento con «Aplicar» / «Ahora no». Dice qué cambia en
/// cada ejercicio con sus cifras («Peso: 40 → 42,5 kg»), por qué (el esfuerzo
/// o los días sin entrenar que manda el servidor), cuándo se nota (desde la
/// próxima vez que se haga ese día de la rutina) y qué pasa si no se aplica.
/// Plegada enseña los primeros ajustes; desplegada, todos.
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
    // El porqué en el idioma de la app si el servidor manda su código; si no
    // (sugerencias antiguas), su descripción.
    final reason = recommendationWhy(l10n, r) ?? r.description?.trim() ?? '';
    final changesRoutine = r.adjustments.isNotEmpty;
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
            if (a.before case final before?)
              for (final line in adjustmentChanges(l10n, before, a.parameters))
                Text(
                  line,
                  semanticsLabel: spokenArrow(l10n, line),
                  style: context.textStyles.bodyMedium,
                )
            else
              ExerciseParameterChips(parameters: a.parameters),
          ],
          if (hidden > 0) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.trainingRecommendationMoreExercises(hidden),
              style: muted,
            ),
          ],
          if (changesRoutine && expanded) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              r.applied
                  ? l10n.trainingRecommendationScopeApplied
                  : l10n.trainingRecommendationScope,
              style: muted,
            ),
            if (!r.applied)
              Text(l10n.trainingRecommendationIfNot, style: muted),
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
                child: Text(l10n.trainingNotNow),
              ),
              AppSecondaryButton(
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

/// Por qué propone el cambio: el motivo de toda la sugerencia lo elige el
/// servidor (cada ejercicio puede tener el suyo); null en las antiguas.
String? recommendationWhy(AppLocalizations l10n, Recommendation r) {
  final rpe = r.rpe;
  return switch (r.reasonCode) {
    AdjustmentReason.failedReps when r.failedReps != null =>
      l10n.trainingWhyFailedReps(r.failedReps!),
    AdjustmentReason.veryHighRpe when rpe != null =>
      l10n.trainingWhyVeryHighRpe(rpe),
    AdjustmentReason.veryLowRpe when rpe != null => l10n.trainingWhyVeryLowRpe(
      rpe,
    ),
    AdjustmentReason.lowRpeMoreReps ||
    AdjustmentReason.lowRpeMoreWeight ||
    AdjustmentReason.lowRpeMoreTime ||
    AdjustmentReason.lowRpeMoreDistance when rpe != null =>
      l10n.trainingWhyLowRpe(rpe),
    AdjustmentReason.inactivity when r.daysInactive != null =>
      l10n.trainingWhyInactivity(r.daysInactive!),
    _ => null,
  };
}

/// Lo que cambia de un ejercicio, una línea por cifra: «Peso: 40 → 42,5 kg».
/// Solo compara lo que manda el servidor (antes y después): no calcula nada.
List<String> adjustmentChanges(
  AppLocalizations l10n,
  ExerciseParameters before,
  ExerciseParameters after,
) {
  String minutes(int seconds) => formatNumber(seconds / 60);
  final bw = before.weightKg;
  final aw = after.weightKg;
  final bt = before.targetDurationSeconds;
  final at = after.targetDurationSeconds;
  final bd = before.distanceMeters;
  final ad = after.distanceMeters;
  final bi = before.isometricSeconds;
  final ai = after.isometricSeconds;
  return [
    if (bw != null && aw != null && (bw - aw).abs() >= 0.05)
      l10n.trainingChangeWeight(formatNumber(bw), formatNumber(aw)),
    if (before.sets != after.sets)
      l10n.trainingChangeSets(before.sets, after.sets),
    if (before.reps != after.reps && bi == null && bt == null)
      l10n.trainingChangeReps(before.reps, after.reps),
    if (bt != null && at != null && bt != at)
      l10n.trainingChangeTime(minutes(bt), minutes(at)),
    if (bd != null && ad != null && bd != ad)
      l10n.trainingChangeDistance(bd, ad),
    if (bi != null && ai != null && bi != ai) l10n.trainingChangeHold(bi, ai),
    if (before.restSeconds != after.restSeconds)
      l10n.trainingChangeRest(before.restSeconds, after.restSeconds),
  ];
}

/// La flecha «→» se lee mal en voz («flecha derecha»): se dice «a».
String spokenArrow(AppLocalizations l10n, String text) =>
    text.replaceAll(' → ', l10n.commonArrowSpoken);
