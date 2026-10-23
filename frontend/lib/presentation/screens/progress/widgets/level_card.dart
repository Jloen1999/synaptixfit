import 'package:flutter/material.dart';

import '../../../../domain/models/account/account.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Nivel del usuario con su barra de XP.
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final remaining = (account.levelThreshold - account.levelXp).clamp(
      0,
      account.levelThreshold,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.accentContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${account.level}',
                  style: context.textStyles.headlineSmall?.copyWith(
                    color: context.palette.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.progressLevelTitle,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      account.fullName,
                      style: context.textStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          XpProgressBar(
            level: account.level,
            levelXp: account.levelXp,
            levelThreshold: account.levelThreshold,
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.progressLevelXpToNext(remaining, account.level + 1),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
