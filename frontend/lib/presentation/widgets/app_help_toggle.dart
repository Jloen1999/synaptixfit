import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.g.dart';

/// Contenido con un «?» opcional al lado que abre y cierra su explicación
/// debajo. Así la explicación no interrumpe ni ocupa sitio hasta que alguien
/// la pide (vocabulario, sección 4). [tooltip] dice de qué es la ayuda.
class AppHelpToggle extends StatefulWidget {
  const AppHelpToggle({
    super.key,
    required this.child,
    required this.help,
    required this.tooltip,
  });

  final Widget child;
  final String help;
  final String tooltip;

  @override
  State<AppHelpToggle> createState() => _AppHelpToggleState();
}

class _AppHelpToggleState extends State<AppHelpToggle> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: widget.child),
            Semantics(
              expanded: _open,
              child: IconButton(
                tooltip: widget.tooltip,
                onPressed: () => setState(() => _open = !_open),
                icon: Icon(
                  AppIcons.help,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
            // Región viva: el lector lee la ayuda al abrirla.
            child: Semantics(
              liveRegion: true,
              child: Text(
                widget.help,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
