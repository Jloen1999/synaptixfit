import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'auth_layout.dart';

/// Marca y título de las pantallas de acceso ([AuthLayout]). La marca solo se
/// pinta si el panel de marca no está ya a la vista.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final showMark = !AuthLayout.showsBrandPanel(context);
    return Column(
      children: [
        if (showMark) ...[
          const AppBrandMark(size: 64),
          const SizedBox(height: TokensSpacing.l),
        ],
        // Título de la página: encabezado para saltar con el lector.
        Semantics(
          header: true,
          child: Text(
            title,
            style: context.textStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: context.textStyles.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
