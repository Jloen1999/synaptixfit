import 'package:flutter/material.dart' hide Badge;

import '../../../../domain/models/progress/badge.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'badge_tile.dart';

/// Vista previa horizontal de las insignias obtenidas.
class EarnedBadgesPreview extends StatelessWidget {
  const EarnedBadgesPreview({
    super.key,
    required this.badges,
    required this.onOpen,
  });

  final List<Badge> badges;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.progressBadgesTitle,
                      style: context.textStyles.titleMedium,
                    ),
                    Text(
                      l10n.progressBadgesEarnedCount(badges.length),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onOpen, child: Text(l10n.commonSeeAll)),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          if (badges.isEmpty)
            Row(
              children: [
                Icon(
                  Icons.military_tech_outlined,
                  color: context.palette.accent,
                  size: 32,
                ),
                const SizedBox(width: TokensSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.progressBadgesEmptyTitle,
                        style: context.textStyles.titleSmall,
                      ),
                      Text(
                        l10n.progressBadgesEmptyMessage,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            SizedBox(
              height: 60 + TokensSpacing.xs + context.scaled(40),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: TokensSpacing.m),
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  // La etiqueta envuelve solo el contenido: el InkWell
                  // conserva su acción y su foco en el mismo nodo.
                  return Semantics(
                    container: true,
                    button: true,
                    label: l10n.progressBadgeSemanticsEarned(badge.name),
                    child: AppFocusOutline(
                      borderRadius: BorderRadius.circular(TokensRadius.m),
                      child: InkWell(
                        onTap: onOpen,
                        borderRadius: BorderRadius.circular(TokensRadius.m),
                        child: ExcludeSemantics(
                          child: SizedBox(
                            // Ancho para que nombres como «Coleccionista»
                            // no se partan a mitad de palabra.
                            width: context.scaled(88),
                            child: Column(
                              children: [
                                BadgeEmblem(badge: badge, size: 60),
                                const SizedBox(height: TokensSpacing.xs),
                                Text(
                                  badge.name,
                                  style: context.textStyles.labelSmall,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
