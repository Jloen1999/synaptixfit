import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Maqueta de las pantallas de acceso: el formulario centrado y, en pantallas
/// anchas y con altura suficiente, un panel de marca que explica qué conecta
/// la app. [AuthHeader] oculta su marca cuando el panel ya la muestra.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.appBar});

  final Widget child;
  final PreferredSizeWidget? appBar;

  /// Si se ve el panel de marca. Con poca altura (horizontal en móvil, zoom)
  /// se oculta para que el formulario tenga todo el espacio.
  static bool showsBrandPanel(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= TokensLayout.railBreakpoint &&
        size.height >= TokensLayout.compactHeight;
  }

  @override
  Widget build(BuildContext context) {
    final form = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TokensSpacing.l),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TokensLayout.formMaxWidth,
            ),
            child: child,
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: appBar,
      body: showsBrandPanel(context)
          ? Row(
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(flex: 6, child: form),
              ],
            )
          : form,
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final points = [
      (Icons.sync_alt_rounded, l10n.authBrandPointLoad),
      (Icons.auto_awesome_rounded, l10n.authBrandPointReview),
      (Icons.emoji_events_outlined, l10n.authBrandPointProgress),
    ];
    // Plano, sin degradado: el color de marca lo pone el monograma.
    return Container(
      margin: const EdgeInsets.all(TokensSpacing.m),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensRadius.xl),
        color: colors.primaryContainer,
      ),
      // Desplazable por si el texto se agranda: nunca se corta.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(TokensSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - TokensSpacing.xl * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBrandMark(size: 64),
                const SizedBox(height: TokensSpacing.xl),
                Text(
                  l10n.authBrandTitle,
                  style: context.textStyles.displaySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: TokensSpacing.xl),
                for (final (icon, text) in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.m),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(TokensSpacing.s),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(TokensRadius.m),
                          ),
                          child: Icon(
                            icon,
                            size: TokensSize.iconS,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: TokensSpacing.m),
                        Expanded(
                          child: Text(
                            text,
                            style: context.textStyles.bodyLarge?.copyWith(
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
