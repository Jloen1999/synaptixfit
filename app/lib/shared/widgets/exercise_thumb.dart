import 'package:flutter/material.dart';

/// Miniatura del ejercicio (imagen/GIF) para identificarlo a primera vista
/// en las pantallas de entrenamiento y de detalle de rutina.
///
/// Usa [urlPreview] (póster estático) si existe; si no, cae en [urlGif]
/// siempre que no sea un vídeo `.mp4`. Muestra un icono de respaldo si no hay
/// media o falla la carga.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb({
    super.key,
    this.urlGif,
    this.urlPreview,
    this.size = 48,
  });

  final String? urlGif;
  final String? urlPreview;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gif = urlGif;
    final url = (urlPreview != null && urlPreview!.isNotEmpty)
        ? urlPreview
        : (gif != null && gif.isNotEmpty && !gif.toLowerCase().endsWith('.mp4')
            ? gif
            : null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: cs.surfaceContainerHighest,
          child: url != null
              ? Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(cs),
                  loadingBuilder: (ctx, child, progress) =>
                      progress == null ? child : _fallback(cs),
                )
              : _fallback(cs),
        ),
      ),
    );
  }

  Widget _fallback(ColorScheme cs) => Center(
        child: Icon(
          Icons.fitness_center_rounded,
          size: size * 0.5,
          color: cs.onSurfaceVariant,
        ),
      );
}
