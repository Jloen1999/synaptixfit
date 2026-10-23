import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/progress/badge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../badges/bloc/badges_bloc.dart';
import 'badge_tile.dart';
import 'progress_labels.dart';

/// Abre la hoja de detalle de una insignia. Se mantiene sincronizada con el
/// [BadgesBloc] para reflejar los cambios de visibilidad al momento.
Future<void> showBadgeDetailSheet(BuildContext context, Badge badge) {
  final bloc = context.read<BadgesBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _BadgeDetailSheet(badgeId: badge.id, initial: badge),
    ),
  );
}

class _BadgeDetailSheet extends StatelessWidget {
  const _BadgeDetailSheet({required this.badgeId, required this.initial});

  final String badgeId;
  final Badge initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<BadgesBloc, BadgesState>(
      builder: (context, state) {
        final badge = state.byId(badgeId) ?? initial;
        final busy = state.busyIds.contains(badgeId);
        final rarityColor = context.rarityColor(badge.rarity);
        final earnedAt = badge.earnedAt;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.l,
            0,
            TokensSpacing.l,
            TokensSpacing.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: BadgeEmblem(badge: badge, size: 88)),
              const SizedBox(height: TokensSpacing.m),
              Text(
                badge.name,
                style: context.textStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TokensSpacing.s),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: TokensSpacing.s,
                runSpacing: TokensSpacing.s,
                children: [
                  _Pill(
                    icon: Icons.diamond_outlined,
                    label: l10n.badgeRarity(badge.rarity),
                    color: rarityColor,
                  ),
                  _Pill(
                    icon: badgeCategoryIcon(badge.category),
                    label: l10n.badgeCategory(badge.category),
                    color: context.colors.onSurfaceVariant,
                  ),
                  _Pill(
                    icon: badge.earned
                        ? Icons.check_circle_rounded
                        : Icons.lock_rounded,
                    label: badge.earned
                        ? l10n.progressBadgeEarned
                        : l10n.progressBadgeLocked,
                    color: badge.earned
                        ? context.palette.success
                        : context.colors.onSurfaceVariant,
                  ),
                ],
              ),
              if (badge.description.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.m),
                Text(
                  badge.description,
                  style: context.textStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: TokensSpacing.l),
              Text(
                l10n.progressBadgeDetailCriterion,
                style: context.textStyles.titleSmall,
              ),
              const SizedBox(height: TokensSpacing.xs),
              Text(
                l10n.badgeCriterion(badge),
                style: context.textStyles.bodyMedium,
              ),
              const SizedBox(height: TokensSpacing.m),
              Text(
                l10n.progressBadgeDetailProgress,
                style: context.textStyles.titleSmall,
              ),
              const SizedBox(height: TokensSpacing.xs),
              BadgeProgressBar(badge: badge),
              if (badge.earned) ...[
                if (earnedAt != null) ...[
                  const SizedBox(height: TokensSpacing.s),
                  Text(
                    l10n.progressBadgeEarnedOn(ProgressFormat.date(earnedAt)),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: TokensSpacing.m),
                const Divider(),
                AppFocusOutline(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.progressBadgeVisibleLabel),
                    subtitle: Text(l10n.progressBadgeVisibleHint),
                    value: badge.visible,
                    onChanged: busy
                        ? null
                        : (visible) => context.read<BadgesBloc>().add(
                            BadgesEvent.visibilityToggled(
                              badge: badge,
                              visible: visible,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
                AppSecondaryButton(
                  label: l10n.progressBadgeShare,
                  icon: const Icon(Icons.share_rounded),
                  onPressed: busy ? null : () => _share(context, badge),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _share(BuildContext context, Badge badge) async {
    final bloc = context.read<BadgesBloc>();
    final message = await showDialog<String>(
      context: context,
      builder: (_) => const _ShareDialog(),
    );
    if (message == null) return;
    bloc.add(BadgesEvent.shareRequested(badge: badge, message: message));
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.s + TokensSpacing.xs,
        vertical: TokensSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TokensRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: TokensSpacing.xs),
          Text(
            label,
            style: context.textStyles.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Pide un comentario opcional antes de publicar; devuelve `null` si se cancela.
class _ShareDialog extends StatefulWidget {
  const _ShareDialog();

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AlertDialog(
      title: Text(l10n.progressBadgeShareTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 500,
        maxLines: 3,
        minLines: 1,
        decoration: InputDecoration(labelText: l10n.progressBadgeShareHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.progressBadgeShareAction),
        ),
      ],
    );
  }
}
