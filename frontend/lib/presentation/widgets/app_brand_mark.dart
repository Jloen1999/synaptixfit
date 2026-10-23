import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Marca de SynaptixFit: monograma plano en el lima de marca con una chispa
/// naranja (el color de logro). Se usa en el acceso, la carga y el riel.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spark = size * 0.22;
    return Semantics(
      label: context.localizations.appName,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(size * 0.3),
                  ),
                  child: Text(
                    'S',
                    style: GoogleFonts.getFont(
                      TokensFont.display,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.52,
                      height: 1,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ),
              // Chispa: un punto ámbar con un anillo del color del monograma
              // para que se separe del borde en los dos temas.
              Positioned(
                top: size * 0.1,
                right: size * 0.1,
                child: Container(
                  width: spark,
                  height: spark,
                  decoration: BoxDecoration(
                    color: context.palette.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.primary,
                      width: size * 0.04,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
