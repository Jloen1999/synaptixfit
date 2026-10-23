import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Indicador de carga centrado, anunciado a los lectores de pantalla.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(
      semanticsLabel: context.localizations.commonLoading,
    ),
  );
}
