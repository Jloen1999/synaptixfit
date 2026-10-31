import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';

/// Miniatura cuadrada de un ejercicio con icono de reserva.
class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({
    super.key,
    required this.url,
    this.size = TokensSize.listTileMin,
    this.icon = Icons.fitness_center_rounded,
  });

  final String? url;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: context.colors.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: context.colors.onSecondaryContainer,
        size: size * 0.45,
      ),
    );
    final image = url;
    // Decorativa: el nombre del ejercicio ya está escrito al lado.
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: SizedBox.square(
          dimension: size,
          child: image == null
              ? placeholder
              : CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => placeholder,
                  errorWidget: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
  }
}
