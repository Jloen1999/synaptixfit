import 'package:flutter/material.dart';

import '../../domain/enums/badge_rarity.dart';
import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_pill.dart';

/// Matriz de escala de grises para las insignias bloqueadas (valor técnico).
const _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 0.6, 0, //
]);

/// Color de cada rareza de insignia (siempre acompañado de su nombre).
extension BadgeRarityColor on BuildContext {
  Color rarityColor(BadgeRarity rarity) => switch (rarity) {
    BadgeRarity.common => colors.onSurfaceVariant,
    BadgeRarity.rare => palette.sessions,
    BadgeRarity.epic => palette.study,
    BadgeRarity.legendary => palette.accent,
  };
}

/// Emoji de una insignia sobre un círculo del color de su rareza; bloqueada,
/// en gris y con candado. Lo usan Progreso y el perfil público. Es decorativo:
/// quien lo usa pone la etiqueta (nombre y estado) para el lector de pantalla.
class AppBadgeEmblem extends StatelessWidget {
  const AppBadgeEmblem({
    super.key,
    required this.icon,
    required this.rarity,
    this.earned = true,
    this.size = TokensSize.emblem,
  });

  final String icon;
  final BadgeRarity rarity;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.rarityColor(rarity);
    final emblem = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned
            ? color.withValues(alpha: AppPill.tintAlpha)
            : context.colors.surfaceContainer,
        border: Border.all(
          color: earned ? color : context.colors.outlineVariant,
          width: TokensSize.emblemBorder,
        ),
      ),
      // El emoji no crece con el texto del sistema: el círculo tiene tamaño
      // fijo y la etiqueta ya nombra la insignia.
      child: Text(
        icon.isEmpty ? '🏅' : icon,
        textScaler: TextScaler.noScaling,
        style: context.textStyles.headlineSmall?.copyWith(
          fontSize: size * 0.48,
        ),
      ),
    );
    if (earned) return ExcludeSemantics(child: emblem);
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ColorFiltered(colorFilter: _greyscale, child: emblem),
          PositionedDirectional(
            end: -TokensSize.emblemBorder,
            bottom: -TokensSize.emblemBorder,
            child: CircleAvatar(
              radius: size * 0.17,
              backgroundColor: context.colors.surfaceContainerHigh,
              child: Icon(
                Icons.lock_rounded,
                size: size * 0.2,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
