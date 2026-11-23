import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_focus_outline.dart';
import 'app_pill.dart';
import 'app_tile_grid.dart';

/// Tarjetita de acceso (Tú › Retos, Tú › Comunidad, Perfil; ADR 0061): icono
/// en un cuadrado de color, nombre y, si hay, el detalle. Se ponen siempre en
/// una [AppShortcutGrid], que decide cuántas caben por fila.
/// El número de [badgeCount] se ve en un globo y también se lee: va en
/// [semanticsLabel] o en [detail], nunca solo en el color.
class AppShortcutTile extends StatelessWidget {
  const AppShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.badgeCount = 0,
    this.semanticsLabel,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Línea pequeña bajo el nombre («2 solicitudes», «58 kg · 165 cm»).
  final String? detail;

  /// Globo con un número (solicitudes que esperan). Cero: sin globo.
  final int badgeCount;

  /// Nombre para el lector cuando el visible se queda corto («Nuevo» →
  /// «Nuevo reto»). Debe contener el texto visible (WCAG 2.5.3).
  final String? semanticsLabel;

  /// Icono sobre el color principal: la acción de crear de la fila.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detail = this.detail;
    final iconBox = AppTintedIcon(icon: icon, emphasized: emphasized);
    final name = semanticsLabel ?? label;
    // La acción va también en el nodo del lector: con `excludeSemantics`, el
    // toque del InkWell no le llegaría (TalkBack y VoiceOver).
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: detail == null ? name : '$name, $detail',
      onTap: onTap,
      excludeSemantics: true,
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.l),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: TokensLayout.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensSpacing.xs,
                  vertical: TokensSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (badgeCount > 0)
                      Badge(
                        label: Text(
                          badgeCount > 99
                              ? context.localizations.socialBadgeOverflow
                              : '$badgeCount',
                        ),
                        child: iconBox,
                      )
                    else
                      iconBox,
                    const SizedBox(height: TokensSpacing.xs),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: context.textStyles.labelLarge,
                    ),
                    if (detail != null)
                      Text(
                        detail,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rejilla de [AppShortcutTile] con una sola regla de ancho para toda la app:
/// cada tarjetita mide al menos [minWidth] y nunca menos que su palabra más
/// larga (nombre o detalle, con el tamaño de letra de la persona). Si no
/// caben todas en una fila, [AppTileGrid] las pasa a filas de la mitad: así
/// ninguna palabra se parte («Publicacio/nes») ni en francés ni al 200 %.
class AppShortcutGrid extends StatelessWidget {
  const AppShortcutGrid({super.key, required this.tiles});

  final List<AppShortcutTile> tiles;

  /// Ancho mínimo de una tarjetita (sin escalar): un toque cómodo.
  static const minWidth = TokensSize.quickActionMinWidth;

  /// Relleno lateral de la tarjetita más su borde.
  static const _chrome = TokensSpacing.xs * 2 + TokensSpacing.xxs;

  @override
  Widget build(BuildContext context) {
    final scale = context.scaled(1);
    var widest = minWidth;
    for (final tile in tiles) {
      for (final (text, style) in [
        (tile.label, context.textStyles.labelLarge),
        if (tile.detail case final detail?)
          (detail, context.textStyles.bodySmall),
      ]) {
        for (final word in text.split(RegExp(r'\s+'))) {
          // Medida con la escala de la persona; la rejilla vuelve a escalar.
          final width = (context.textWidth(word, style) + _chrome) / scale;
          if (width > widest) widest = width;
        }
      }
    }
    return AppTileGrid(minTileWidth: widest, children: tiles);
  }
}

/// Icono en un cuadradito de color (el de [AppShortcutTile]): también va a
/// la izquierda de las filas que abren algo, como «Con amigos ahora».
class AppTintedIcon extends StatelessWidget {
  const AppTintedIcon({super.key, required this.icon, this.emphasized = false});

  final IconData icon;

  /// Sobre el color principal (la acción de crear); si no, un tinte suave.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: TokensSize.thumbnailXs,
      height: TokensSize.thumbnailXs,
      decoration: BoxDecoration(
        color: emphasized
            ? colors.primary
            : Color.alphaBlend(
                colors.primary.withValues(alpha: AppPill.tintAlpha),
                colors.surface,
              ),
        borderRadius: BorderRadius.circular(TokensRadius.m),
      ),
      child: Icon(
        icon,
        size: TokensSize.iconS,
        color: emphasized ? colors.onPrimary : colors.primary,
      ),
    );
  }
}
