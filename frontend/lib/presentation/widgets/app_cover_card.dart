import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_card.dart';
import 'app_pill.dart';

/// Tarjeta con foto. Con texto normal, la foto se ve tal cual en el lado final
/// de la cabecera ([child], [TokensLayout.coverPhotoShare] del ancho), fundida
/// con la superficie, y el texto queda en la zona lisa: se ve bien la foto y el
/// texto cumple AA con cualquier imagen (no pisa la foto). El [footer]
/// (botones, progreso, listas) va debajo a todo el ancho, sin foto. Con texto
/// grande (necesita el ancho entero) o sin foto, se usa el fondo a dos tonos
/// de abajo.
///
/// Contraste del fondo a dos tonos: la foto se pasa a escala de grises y se lleva al rango que va de
/// la superficie a [tint] (una mezcla de `primary` sobre la superficie,
/// `coverTintLight`/`coverTintDark`). Ningún píxel queda fuera de ese rango,
/// así que el texto en `onSurface`, `onSurfaceVariant` y `primary` cumple AA
/// sea cual sea la foto (`contrast_test.dart`). Las pastillas van sobre una
/// base opaca ([AppCoverCard.solid]). Lo oscuro de la foto va al extremo más
/// oscuro en los dos temas, para que no se vea en negativo. La foto y el velo
/// se pintan con `Ink`: la onda del toque se ve por encima. La foto es
/// decorativa: el lector no la anuncia.
class AppCoverCard extends StatelessWidget {
  const AppCoverCard({
    super.key,
    required this.child,
    this.imageUrl,
    this.onTap,
    this.padding = const EdgeInsets.all(TokensSpacing.l),
    this.footer,
  });

  /// Cabecera: lo que se lee de un vistazo (junto a la foto).
  final Widget child;

  /// Lo que necesita el ancho entero (botón principal, progreso, acciones).
  final Widget? footer;
  final String? imageUrl;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Extremo de color de la foto (y del degradado) distinto de la superficie.
  static Color tint(BuildContext context) {
    final scheme = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Color.lerp(
      scheme.surface,
      scheme.primary,
      dark ? TokensOpacity.coverTintDark : TokensOpacity.coverTintLight,
    )!;
  }

  /// Base opaca para lo que no es texto suelto (pastillas): su contraste es
  /// el de siempre, el de la superficie.
  static Widget solid(BuildContext context, Widget child) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(TokensRadius.pill),
    ),
    child: child,
  );

  /// Matriz que lleva la luminancia de cada píxel de [from] (negro) a [to]
  /// (blanco): `salida = from + (to − from) × luminancia`.
  static ColorFilter _duotone(Color from, Color to) {
    List<double> row(double a, double b) {
      final d = b - a;
      return [d * 0.2126, d * 0.7152, d * 0.0722, 0, a * 255];
    }

    return ColorFilter.matrix([
      ...row(from.r, to.r),
      ...row(from.g, to.g),
      ...row(from.b, to.b),
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && !context.largeText) return _sidePhoto(context, url);
    return _duotoneBackground(context, url);
  }

  /// Foto visible en el lado final y texto sobre la superficie lisa.
  Widget _sidePhoto(BuildContext context, String url) {
    final surface = context.colors.surface;
    return AppCard(
      color: surface,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final photo = constraints.maxWidth * TokensLayout.coverPhotoShare;
          final header = Stack(
            children: [
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 0,
                width: photo,
                child: Ink(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(url),
                      fit: BoxFit.cover,
                      // Sin foto (error de red) queda la superficie.
                      onError: (_, _) {},
                    ),
                  ),
                ),
              ),
              // Funde el borde de la foto con la superficie (sin corte duro).
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 0,
                width: photo,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [surface, surface.withValues(alpha: 0)],
                      stops: const [0, TokensLayout.coverPhotoFade],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding.add(EdgeInsetsDirectional.only(end: photo)),
                child: child,
              ),
            ],
          );
          final footer = this.footer;
          if (footer == null) return header;
          final resolved = padding.resolve(Directionality.of(context));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Padding(
                padding: EdgeInsets.fromLTRB(
                  resolved.left,
                  0,
                  resolved.right,
                  resolved.bottom,
                ),
                child: footer,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _duotoneBackground(BuildContext context, String? url) {
    final surface = context.colors.surface;
    final tinted = tint(context);
    final darkFirst = tinted.computeLuminance() < surface.computeLuminance();
    return AppCard(
      color: surface,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: url == null
                // Sin foto, un degradado del mismo tono: nada con forma que
                // compita con el texto que va encima.
                ? Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [surface, tinted],
                      ),
                    ),
                  )
                : Ink(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(url),
                        fit: BoxFit.cover,
                        alignment: AlignmentDirectional.centerEnd.resolve(
                          Directionality.of(context),
                        ),
                        colorFilter: darkFirst
                            ? _duotone(tinted, surface)
                            : _duotone(surface, tinted),
                        // Sin foto (error de red) queda la superficie.
                        onError: (_, _) {},
                      ),
                    ),
                  ),
          ),
          Positioned.fill(
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [
                    surface.withValues(alpha: TokensOpacity.coverScrimMax),
                    surface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: footer == null
                ? child
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [child, footer!],
                  ),
          ),
        ],
      ),
    );
  }
}

/// [AppPill] sobre una base opaca de superficie, para usarla encima de la foto
/// de un [AppCoverCard]: su contraste es el de una pastilla normal.
class AppCoverPill extends StatelessWidget {
  const AppCoverPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => AppCoverCard.solid(
    context,
    AppPill(
      label: label,
      color: color,
      icon: icon,
      semanticLabel: semanticLabel,
    ),
  );
}
