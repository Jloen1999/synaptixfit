import 'package:flutter/material.dart';

import '../../../../domain/models/challenges/pending_milestone.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'challenge_labels.dart';

/// Tarea pendiente con casilla para completarla sin entrar al reto.
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
    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.s,
        vertical: TokensSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(TokensSpacing.m),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: l10n.challengesPendingComplete(milestone.title),
                    onPressed: onComplete,
                    icon: Icon(
                      Icons.check_box_outline_blank_rounded,
                      color: context.colors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: TokensSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyLarge,
                ),
                Text(
                  l10n.challengesFeedbackJoin(
                    pending.challengeTitle,
                    l10n.challengesEndsOn(
                      ChallengeFormats.shortDate(pending.challengeEndAt),
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            milestone.status.icon,
            size: 18,
            color: milestone.status.color(context),
            semanticLabel: milestone.status.label(context),
          ),
          const SizedBox(width: TokensSpacing.s),
        ],
      ),
    );
  }
}
