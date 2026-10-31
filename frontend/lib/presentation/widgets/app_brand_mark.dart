import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Logo de SynaptixFit (`assets/images/logo.png`, circular). Se usa en el
/// acceso, la pantalla de carga y el riel lateral; los iconos de la app salen
/// del mismo archivo (`tools/brand/generate_icons.py`).
/// [decorative] la oculta al lector cuando el nombre ya aparece al lado.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 56, this.decorative = false});

  static const asset = 'assets/images/logo.png';

  final double size;
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    if (decorative) return ExcludeSemantics(child: _image(context));
    return Semantics(
      label: context.localizations.appName,
      image: true,
      child: ExcludeSemantics(child: _image(context)),
    );
  }

  Widget _image(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        // Se decodifica al tamaño mostrado (el original es de 996 px).
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      ),
    );
  }
}
