import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../extensions/context_extensions.dart';
import '../../../widgets/widgets.dart';
import '../../home/home_routes.dart';

/// Dirección que la app no conoce (un enlace o un aviso de una versión
/// anterior): lo dice con el tema y el idioma de la app y lleva a Inicio, en
/// lugar de la página de error en inglés de go_router.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar(
        leading: const AppBackButton(fallback: HomePaths.root),
        title: Text(l10n.appName),
      ),
      body: AppEmptyState(
        icon: AppIcons.search,
        title: l10n.errorNotFound,
        action: AppPrimaryButton(
          label: l10n.commonGoHome,
          icon: AppIcons.tabHome,
          onPressed: () => context.go(HomePaths.root),
        ),
      ),
    );
  }
}
