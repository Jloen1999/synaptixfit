import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Fila de usuario: avatar, nombre, nivel y acciones a la derecha.
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.name,
    this.avatarUrl,
    this.level,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final int? level;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final details = [
      if (level != null) l10n.commonLevel(level!),
      ?subtitle,
    ].join(' · ');
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.m,
        vertical: TokensSpacing.s,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: TokensLayout.minTouchTarget,
        ),
        child: Row(
          children: [
            AppAvatar(name: name, imageUrl: avatarUrl),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: context.textStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: TokensSpacing.s),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Indicador pequeño para una acción en curso dentro de una fila.
class BusyIndicator extends StatelessWidget {
  const BusyIndicator({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 44,
    child: Padding(
      padding: EdgeInsets.all(TokensSpacing.m - TokensSpacing.xxs),
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}
