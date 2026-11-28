import 'package:flutter/material.dart';

import '../../../../../domain/models/training/wod.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/wod_labels.dart';

/// La pizarra del WOD, como un ticket (ADR 0069): si es de ejemplo lo dice
/// una pastilla (no solo el color); título, formato con cifras grandes, límite
/// de tiempo, los movimientos con la cantidad en negrita, Rx o Adaptado y, al
/// pie, la mejor marca y la de hoy. «Editar» parte de lo que se ve.
class WodBoardCard extends StatelessWidget {
  const WodBoardCard({
    super.key,
    required this.board,
    required this.division,
    required this.onDivisionChanged,
    required this.onEdit,
    this.onChangeExample,
  });

  final WodBoard board;
  final WodDivision division;
  final ValueChanged<WodDivision> onDivisionChanged;
  final VoidCallback onEdit;

  /// Nulo si no hay otra plantilla que enseñar o el WOD es de la persona.
  final VoidCallback? onChangeExample;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final styles = context.textStyles;
    final colors = context.colors;
    final wod = board.wod;
    final muted = styles.bodySmall?.copyWith(color: colors.onSurfaceVariant);
    // Cifras de ancho fijo, como en un ticket, con la letra del tema.
    final line = styles.titleMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final best = board.best(division);
    final today = board.todayResult;
    final cap = WodLabels.timeCap(l10n, wod);
    return Semantics(
      container: true,
      label: l10n.wodBoardLabel,
      child: AppCard(
        color: colors.surfaceContainerLow,
        padding: const EdgeInsets.all(TokensSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (board.example) ...[
              AppPill(label: l10n.wodExamplePill, icon: AppIcons.info),
              const SizedBox(height: TokensSpacing.s),
            ],
            Semantics(
              header: true,
              child: Text(WodLabels.title(l10n, wod), style: styles.titleLarge),
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              WodLabels.headline(l10n, wod).toUpperCase(),
              style: styles.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (cap != null) Text(cap, style: styles.bodyMedium),
            Text(WodLabels.formatHelp(l10n, wod.format), style: muted),
            if (wod.strength case final strength?) ...[
              const SizedBox(height: TokensSpacing.s),
              Text('${l10n.wodStrength}: $strength', style: styles.bodyMedium),
            ],
            const Divider(height: TokensSpacing.l),
            for (final m in wod.movements)
              Padding(
                padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                child: WodMovementLine(
                  movement: m,
                  division: division,
                  style: line,
                ),
              ),
            const Divider(height: TokensSpacing.l),
            AppSegmentedChoice<WodDivision>(
              label: l10n.wodDivisionLabel,
              values: WodDivision.values,
              selected: division,
              labelOf: (d) => WodLabels.division(l10n, d),
              spokenLabelOf: (d) => d == WodDivision.rx
                  ? l10n.wodDivisionRxSpoken
                  : l10n.wodDivisionScaled,
              onChanged: (d) {
                if (d != null) onDivisionChanged(d);
              },
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(l10n.wodDivisionHelp, style: muted),
            const Divider(height: TokensSpacing.l),
            _Fact(
              icon: AppIcons.badge,
              text: best == null
                  ? l10n.wodNoBestMark
                  : l10n.wodBestMark(WodLabels.score(l10n, best)),
            ),
            const SizedBox(height: TokensSpacing.xs),
            _Fact(
              icon: AppIcons.today,
              text: today == null
                  ? l10n.wodTodayNone
                  : l10n.wodTodayMark(
                      l10n.wodMarkLine(
                        WodLabels.score(l10n, today),
                        WodLabels.division(l10n, today.division),
                      ),
                    ),
            ),
            const SizedBox(height: TokensSpacing.s),
            Wrap(
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.xs,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(AppIcons.edit),
                  label: Text(l10n.wodEdit),
                ),
                if (onChangeExample != null)
                  TextButton.icon(
                    onPressed: onChangeExample,
                    icon: const Icon(AppIcons.swap),
                    label: Text(l10n.wodChangeExample),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Icon(
          icon,
          size: TokensSize.iconS,
          color: context.colors.onSurfaceVariant,
        ),
      ),
      const SizedBox(width: TokensSpacing.s),
      Expanded(child: Text(text, style: context.textStyles.bodyMedium)),
    ],
  );
}
