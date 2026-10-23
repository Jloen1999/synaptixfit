import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_skeleton.dart';

/// Agrupa los [AppSkeleton] de un estado de carga y lo anuncia una sola vez
/// como «Cargando» (WCAG 4.1.3): cada bloque por separado es mudo.
class AppSkeletonGroup extends StatelessWidget {
  const AppSkeletonGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: context.localizations.commonLoading,
    child: child,
  );
}

/// Lista de esqueletos iguales para el estado de carga de un listado.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    super.key,
    this.count = 4,
    this.height = 72,
    this.padding = const EdgeInsets.all(TokensSpacing.m),
  });

  final int count;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => AppSkeletonGroup(
    child: ListView.separated(
      // Sin desplazamiento propio: es un hueco temporal, no contenido.
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: TokensSpacing.s),
      itemBuilder: (_, _) => AppSkeleton(height: height),
    ),
  );
}
