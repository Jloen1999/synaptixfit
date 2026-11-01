import 'package:flutter/material.dart';

import '../../../../domain/enums/milestone_condition.dart';
import '../../../../domain/enums/milestone_status.dart';
import '../../../../domain/models/challenges/challenge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'challenge_labels.dart';
import 'challenge_progress_bar.dart';

/// Tarea de un reto en el detalle: estado, XP real (con el tope del reto),
/// qué la completa si no es un toque (su entrega o sus bloques), dependencias,
/// adjuntos y casilla para completarla. Solo muestra lo que aporta:
/// «Disponible» se da por hecho.
class MilestoneTile extends StatelessWidget {
  const MilestoneTile({
    super.key,
    required this.milestone,
    required this.dependencyTitles,
    required this.busy,
    this.isNext = false,
    this.expired = false,
    this.onToggle,
    this.onOpenNote,
    this.onOpenFile,
    this.onOpenLink,
  });

  final Milestone milestone;
  final List<String> dependencyTitles;
  final bool busy;

  /// Es la siguiente tarea que toca: se marca con «Siguiente».
  final bool isNext;

  /// El reto venció: la tarea pendiente ya no se puede completar.
  final bool expired;

  /// `null` en retos ajenos (solo lectura).
  final VoidCallback? onToggle;
  final VoidCallback? onOpenNote;
  final VoidCallback? onOpenFile;
  final VoidCallback? onOpenLink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final status = milestone.status;
    final locked = milestone.isLocked;
    final link = milestone.link;
    final source = milestone.sourceText(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.xs,
        TokensSpacing.s,
        TokensSpacing.m,
        TokensSpacing.m,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: TokensLayout.minTouchTarget,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(TokensSpacing.m),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: locked
                        ? l10n.challengesMilestoneLockedHint
                        : source ??
                              (expired && !milestone.completed
                                  ? l10n.challengesExpiredHint
                                  : milestone.completed
                                  ? l10n.challengesMilestoneUncomplete(
                                      milestone.title,
                                    )
                                  : l10n.challengesMilestoneComplete(
                                      milestone.title,
                                    )),
                    onPressed: locked ? null : onToggle,
                    icon: Icon(
                      milestone.completed
                          ? Icons.check_box_rounded
                          : locked
                          ? Icons.lock_outline_rounded
                          : milestone.completedByLink
                          ? (link == null
                                ? Icons.event_available_outlined
                                : Icons.link_rounded)
                          : Icons.check_box_outline_blank_rounded,
                      color: status.color(context),
                    ),
                  ),
          ),
          const SizedBox(width: TokensSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: TokensSpacing.s),
                Text(
                  milestone.title,
                  style: context.textStyles.bodyLarge?.copyWith(
                    decoration: milestone.completed
                        ? TextDecoration.lineThrough
                        : null,
                    color: locked ? context.colors.onSurfaceVariant : null,
                  ),
                ),
                const SizedBox(height: TokensSpacing.xs),
                Wrap(
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.xs,
                  children: [
                    if (isNext)
                      AppPill(
                        icon: Icons.arrow_forward_rounded,
                        label: l10n.challengesMilestoneNext,
                        color: context.colors.primary,
                      )
                    else if (status != MilestoneStatus.available)
                      AppPill(
                        icon: status.icon,
                        label: status.label(context),
                        color: status.color(context),
                      ),
                    // XP real: con el tope del reto puede ser 0; entonces no se
                    // promete nada.
                    if (milestone.xpReward > 0)
                      AppPill(
                        icon: Icons.bolt_rounded,
                        label: l10n.challengesXpGain(milestone.xpReward),
                        color: context.palette.accent,
                      ),
                  ],
                ),
                if (source != null) ...[
                  const SizedBox(height: TokensSpacing.s),
                  Text(
                    source,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (status == MilestoneStatus.inProgress) ...[
                  const SizedBox(height: TokensSpacing.s),
                  ChallengeProgressBar(
                    value: milestone.progress / 100,
                    color: status.color(context),
                  ),
                ],
                if (dependencyTitles.isNotEmpty) ...[
                  const SizedBox(height: TokensSpacing.s),
                  Text(
                    _dependencyText(context),
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (milestone.noteId != null ||
                    milestone.fileId != null ||
                    link != null) ...[
                  const SizedBox(height: TokensSpacing.xs),
                  Wrap(
                    spacing: TokensSpacing.s,
                    children: [
                      if (milestone.noteId != null)
                        ActionChip(
                          avatar: const Icon(Icons.description_outlined),
                          label: Text(l10n.challengesMilestoneNote),
                          onPressed: onOpenNote,
                        ),
                      if (milestone.fileId != null)
                        ActionChip(
                          avatar: const Icon(Icons.attach_file_rounded),
                          label: Text(l10n.challengesMilestoneFile),
                          onPressed: onOpenFile,
                        ),
                      if (link != null && onOpenLink != null)
                        ActionChip(
                          avatar: Icon(link.type.icon),
                          label: Text(context.localizations.challengesLinkOpen),
                          onPressed: onOpenLink,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dependencyText(BuildContext context) {
    final l10n = context.localizations;
    final titles = dependencyTitles.join(', ');
    final base = l10n.challengesMilestoneDependsOn(titles);
    if (dependencyTitles.length < 2) return base;
    final condition = milestone.condition.label(
      context,
      n: milestone.condition == MilestoneCondition.xOfY
          ? milestone.conditionN
          : 1,
      total: dependencyTitles.length,
    );
    return l10n.challengesFeedbackJoin(base, condition);
  }
}
