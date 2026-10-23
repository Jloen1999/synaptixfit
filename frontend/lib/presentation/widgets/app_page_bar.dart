import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

/// Barra superior de las páginas. En pantallas anchas se centra con el mismo
/// ancho que [AppContentWidth], así el título y las acciones quedan alineados
/// con el contenido en lugar de pegados a los bordes de la ventana.
class AppPageBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.maxWidth = TokensLayout.contentMaxWidth,
  });

  /// Para páginas de formulario o lectura ([AppContentWidth.reading]).
  const AppPageBar.reading({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
  }) : maxWidth = TokensLayout.readingMaxWidth;

  /// Para paneles de varias columnas ([AppContentWidth.wide]).
  const AppPageBar.wide({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
  }) : maxWidth = TokensLayout.wideMaxWidth;

  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double maxWidth;

  // El alto lo fija el tema (`appBarTheme.toolbarHeight`) con el mismo token.
  @override
  Size get preferredSize => Size.fromHeight(
    TokensSize.toolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final background =
        Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;
    // El margen lateral de la barra (16) se suma al ancho para que el título
    // empiece justo donde empieza el contenido.
    return ColoredBox(
      color: background,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth + TokensSpacing.m * 2),
          child: AppBar(
            title: title,
            actions: [
              ...?actions,
              const SizedBox(width: TokensSpacing.xs),
            ],
            bottom: bottom,
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
          ),
        ),
      ),
    );
  }
}
