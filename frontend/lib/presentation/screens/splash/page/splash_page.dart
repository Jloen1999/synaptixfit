import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Pantalla mostrada mientras se recupera la sesión.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const path = '/splash';

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBrandMark(size: 80),
            const SizedBox(height: TokensSpacing.l),
            Text(l10n.appName, style: context.textStyles.headlineSmall),
            const SizedBox(height: TokensSpacing.xl),
            SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                semanticsLabel: l10n.splashLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
