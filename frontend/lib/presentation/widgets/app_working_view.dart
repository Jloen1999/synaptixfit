import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// «Trabajando…» a pantalla completa mientras el servidor hace algo largo
/// (leer fotos, generar con IA): icono, barra y texto. Es región viva para
/// que el lector de pantalla lo anuncie, y con «reducir movimiento» la barra
/// no se anima.
class AppWorkingView extends StatelessWidget {
  const AppWorkingView({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
  });

  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TokensSpacing.xl),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                size: TokensSize.iconXl,
                color: context.colors.tertiary,
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            ExcludeSemantics(
              child: SizedBox(
                width: TokensSize.progressInline,
                // Sin animación, una barra quieta a medias dice «en marcha»
                // igual de bien.
                child: LinearProgressIndicator(
                  value: context.reduceMotion ? 0.5 : null,
                ),
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium,
            ),
            if (hint != null) ...[
              const SizedBox(height: TokensSpacing.xs),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
