import 'package:flutter/material.dart';

import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Esqueleto de carga con la forma del inicio: saludo, «Tu día», agenda
/// (cabecera, tira de días y dos eventos) y la tarjeta compacta de estado.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeleton(height: TokensSize.toolbarHeight),
          SizedBox(height: TokensSpacing.l),
          // «Tu día»: anillo, botón y cifras con el relleno de la tarjeta.
          AppSkeleton(
            height:
                TokensSize.heroRing +
                TokensSize.controlHeight +
                5 * TokensSpacing.m,
          ),
          SizedBox(height: TokensSpacing.l),
          AppSkeleton(height: TokensSize.iconM),
          SizedBox(height: TokensSpacing.s),
          AppSkeleton(height: TokensSize.dayChipHeight),
          SizedBox(height: TokensSpacing.s),
          AppSkeleton(height: TokensSize.listTileMin),
          SizedBox(height: TokensSpacing.s),
          AppSkeleton(height: TokensSize.listTileMin),
          SizedBox(height: TokensSpacing.l),
          AppSkeleton(height: TokensSize.iconM),
          SizedBox(height: TokensSpacing.s),
          AppSkeleton(height: TokensSize.medallion),
        ],
      ),
    );
  }
}
