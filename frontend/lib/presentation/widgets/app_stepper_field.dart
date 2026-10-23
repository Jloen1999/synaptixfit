import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Selector numérico con botones − / + (objetivos táctiles de 48 dp). El valor
/// se anuncia al cambiar y, al llegar a un extremo, el foco pasa al botón
/// contrario en vez de perderse (WCAG 2.4.3 y 4.1.3).
class AppStepperField extends StatefulWidget {
  const AppStepperField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.display,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  /// Cómo se muestra el valor (p. ej. «25 min»); por defecto, el número.
  final String Function(int value)? display;

  @override
  State<AppStepperField> createState() => _AppStepperFieldState();
}

class _AppStepperFieldState extends State<AppStepperField> {
  final _decrease = FocusNode();
  final _increase = FocusNode();

  bool get _canDecrease => widget.value > widget.min;
  bool get _canIncrease => widget.value < widget.max;

  @override
  void didUpdateWidget(AppStepperField old) {
    super.didUpdateWidget(old);
    if (!_canDecrease && _decrease.hasFocus) {
      _increase.requestFocus();
    } else if (!_canIncrease && _increase.hasFocus) {
      _decrease.requestFocus();
    }
  }

  @override
  void dispose() {
    _decrease.dispose();
    _increase.dispose();
    super.dispose();
  }

  // Sin salirse de los límites: el último paso se queda en el mínimo o máximo.
  int _clamped(int v) => v.clamp(widget.min, widget.max);

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final w = widget;
    final text = w.display?.call(w.value) ?? '${w.value}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(w.label, style: context.textStyles.bodyLarge)),
          IconButton.outlined(
            focusNode: _decrease,
            tooltip: l10n.commonDecrease(w.label),
            onPressed: _canDecrease
                ? () => w.onChanged(_clamped(w.value - w.step))
                : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: context.scaled(TokensSize.stepperValue),
            child: Semantics(
              liveRegion: true,
              label: w.label,
              value: text,
              excludeSemantics: true,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: context.textStyles.titleMedium,
              ),
            ),
          ),
          IconButton.outlined(
            focusNode: _increase,
            tooltip: l10n.commonIncrease(w.label),
            onPressed: _canIncrease
                ? () => w.onChanged(_clamped(w.value + w.step))
                : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
