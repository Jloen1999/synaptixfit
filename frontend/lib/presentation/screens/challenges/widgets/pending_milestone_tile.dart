import 'package:flutter/material.dart';

import '../../../../domain/models/challenges/pending_milestone.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'challenge_labels.dart';

/// Tarea pendiente de un reto en curso, para hacerla sin entrar al reto: a la
/// izquierda una franja con el acento de su tipo; luego la casilla (o, si la
/// completa su entrega o sus bloques, un icono que lo dice), el título y una
/// pastilla con cuándo vence su reto, en aviso si es hoy o mañana.
class PendingMilestoneTile extends StatelessWidget {
  const PendingMilestoneTile({
    super.key,
    required this.pending,
    required this.busy,
    required this.onComplete,
    required this.onOpen,
  });

  final PendingMilestone pending;
  final bool busy;
  final VoidCallback onComplete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final milestone = pending.milestone;
    final now = DateTime.now();
    final days = ChallengeFormats.daysLeft(pending.challengeEndAt, now);
    final urgent = days <= challengeUrgentDays;
    final source = milestone.sourceText(context);
    return AppCard(
      onTap: onOpen,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Container(
                width: TokensSize.blockStripe,
                color: pending.challengeType.color(context),
              ),
            ),
            const SizedBox(width: TokensSpacing.xs),
            Center(
              child: SizedBox.square(
                dimension: TokensLayout.minTouchTarget,
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(TokensSpacing.m),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : milestone.completedByLink
                    // La completa su entrega o sus bloques: no hay casilla que
                    // fallaría; el icono lo dice y el toque abre el reto.
                    ? Tooltip(
                        message: source ?? '',
                        child: Icon(
                          milestone.link == null
                              ? Icons.event_available_outlined
                              : Icons.link_rounded,
                          color: context.colors.onSurfaceVariant,
                        ),
                      )
                    : IconButton(
                        tooltip: l10n.challengesPendingComplete(
                          milestone.title,
                        ),
                        onPressed: onComplete,
                        icon: Icon(
                          AppIcons.todo,
                          color: context.colors.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: TokensSpacing.xs),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: TokensSpacing.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      milestone.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodyLarge,
                    ),
                    const SizedBox(height: TokensSpacing.xxs),
                    Text(
                      source ?? pending.challengeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    AppPill(
                      icon: urgent
                          ? Icons.hourglass_bottom_rounded
                          : Icons.event_outlined,
                      label: challengeDueText(
                        context,
                        pending.challengeEndAt,
                        now,
                      ),
                      color: urgent
                          ? context.palette.warning
                          : context.colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: TokensSpacing.m),
          ],
        ),
      ),
    );
  }
}
