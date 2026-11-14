import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_pill.dart';

/// Tono de [AppInlineMessage]: color e icono.
/// [info]: un dato que conviene saber (no es un fallo ni un riesgo).
enum AppMessageTone { error, warning, success, info }

/// Aviso en línea junto a lo que lo provoca (un campo, una hoja inferior):
/// a diferencia de un SnackBar, no se cierra solo ni queda oculto. Es región
/// viva: el lector de pantalla lo lee al aparecer o cambiar.
class AppInlineMessage extends StatelessWidget {
  const AppInlineMessage({
    super.key,
    required this.message,
    this.tone = AppMessageTone.error,
  });

  final String message;
  final AppMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (tone) {
      AppMessageTone.error => (
        context.colors.error,
        Icons.error_outline_rounded,
      ),
      AppMessageTone.warning => (
        context.palette.warning,
        Icons.info_outline_rounded,
      ),
      AppMessageTone.success => (
        context.palette.success,
        Icons.check_circle_outline_rounded,
      ),
      AppMessageTone.info => (
        context.colors.onSurfaceVariant,
        Icons.info_outline_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(TokensSpacing.s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppPill.tintAlpha),
        borderRadius: BorderRadius.circular(TokensRadius.m),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: TokensSize.iconS),
          const SizedBox(width: TokensSpacing.s),
          // La región viva es solo el texto: es lo que se anuncia (el icono
          // es decorativo).
          Expanded(
            child: Semantics(
              container: true,
              liveRegion: true,
              child: Text(message, style: context.textStyles.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
