import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Fila de usuario: avatar, nombre, nivel (en el acento de logro) y una línea
/// de contexto; las acciones van a la derecha o, con el texto grande o poco
/// ancho, debajo. La identidad abre el perfil y es un botón aparte de las
/// acciones (sin toques anidados). [highlight] marca con una franja de color
/// lo que pide actuar (una solicitud recibida).
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.name,
    this.avatarUrl,
    this.level,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.highlight,
  });

  final String name;
  final String? avatarUrl;
  final int? level;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final level = this.level;
    final subtitle = this.subtitle;
    final identity = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: TokensLayout.minTouchTarget),
      child: Row(
        children: [
          AppAvatar(name: name, imageUrl: avatarUrl),
          const SizedBox(width: TokensSpacing.sm),
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
                if (level != null || subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                    child: Wrap(
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (level != null)
                          AppPill(
                            icon: Icons.military_tech_rounded,
                            label: l10n.commonLevel(level),
                            color: context.palette.accent,
                          ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: context.textStyles.labelMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    final tappable = onTap == null
        ? Padding(
            padding: const EdgeInsets.all(TokensSpacing.xs),
            child: identity,
          )
        : AppCardTapArea(
            onTap: onTap,
            // Sin las iniciales del avatar y diciendo qué hace el toque.
            semanticLabel: [
              l10n.socialOpenProfileOf(name),
              if (level != null) l10n.commonLevel(level),
              ?subtitle,
            ].join(', '),
            padding: const EdgeInsets.all(TokensSpacing.xs),
            child: identity,
          );
    final highlight = this.highlight;
    return AppCard(
      padding: EdgeInsets.zero,
      // La franja va en el borde de inicio; la tarjeta recorta las esquinas.
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: highlight == null
              ? null
              : BorderDirectional(
                  start: BorderSide(
                    color: highlight,
                    width: TokensSize.blockStripe,
                  ),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TokensSpacing.xs),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trailing = this.trailing;
              if (trailing == null) return tappable;
              // Con el texto grande o poco ancho, las acciones bajan.
              final stacked =
                  context.largeText ||
                  constraints.maxWidth <
                      context.scaled(TokensLayout.cardActionsInlineMin);
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tappable,
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: trailing,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: tappable),
                  const SizedBox(width: TokensSpacing.xs),
                  trailing,
                ],
              );
            },
          ),
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
    dimension: TokensLayout.minTouchTarget,
    child: Padding(
      padding: EdgeInsets.all(TokensSpacing.m),
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}
