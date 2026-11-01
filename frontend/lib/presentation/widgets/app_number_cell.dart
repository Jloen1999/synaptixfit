import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Celda numérica editable de una tabla (repeticiones, kilos, segundos…).
///
/// Parece un campo (relleno y borde del tema), abre el teclado numérico y solo
/// confirma al terminar (Intro o al salir del campo), así no se guarda a cada
/// tecla. Un valor fuera de [min]–[max] deja el borde en rojo, se anuncia con
/// [invalidMessage] y no se confirma. La etiqueta visible es la cabecera de la
/// columna; el lector oye [semanticLabel] («Serie 2, repeticiones»).
class AppNumberCell extends StatefulWidget {
  const AppNumberCell({
    super.key,
    required this.value,
    required this.semanticLabel,
    required this.min,
    required this.max,
    required this.onCommitted,
    required this.invalidMessage,
    this.decimal = false,
    this.allowEmpty = false,
    this.hint,
    this.enabled = true,
    this.emphasized = false,
    this.onValidityChanged,
  });

  final num? value;
  final String semanticLabel;
  final num min;
  final num max;

  /// Valor confirmado (nulo si se vació y [allowEmpty]).
  final ValueChanged<num?> onCommitted;

  /// Texto que se anuncia cuando el valor está fuera de rango.
  final String invalidMessage;
  final bool decimal;
  final bool allowEmpty;

  /// Lo que se ve con la celda vacía (p. ej. el objetivo de hoy).
  final String? hint;
  final bool enabled;

  /// Cifra grande (la serie que toca).
  final bool emphasized;
  final ValueChanged<bool>? onValidityChanged;

  @override
  State<AppNumberCell> createState() => _AppNumberCellState();
}

class _AppNumberCellState extends State<AppNumberCell> {
  late final _controller = TextEditingController(text: _format(widget.value));
  final _focus = FocusNode();
  bool _invalid = false;

  /// Último valor enviado: Intro y la pérdida de foco no lo envían dos veces.
  num? _sent;

  static String _format(num? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        _commit();
      } else {
        // Al entrar se selecciona todo: se escribe encima sin borrar a mano.
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void didUpdateWidget(AppNumberCell old) {
    super.didUpdateWidget(old);
    // Lo que llega de fuera (guardado, otra serie…) no pisa lo que se escribe.
    if (old.value != widget.value) _sent = null;
    if (!_focus.hasFocus && old.value != widget.value) {
      _controller.text = _format(widget.value);
      _setInvalid(false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setInvalid(bool invalid) {
    if (_invalid == invalid) return;
    setState(() => _invalid = invalid);
    widget.onValidityChanged?.call(!invalid);
  }

  void _commit() {
    final text = _controller.text.trim().replaceAll(',', '.');
    if (text.isEmpty) {
      if (widget.allowEmpty) {
        _setInvalid(false);
        if (widget.value != null && _sent != -1) {
          _sent = -1;
          widget.onCommitted(null);
        }
      } else {
        _controller.text = _format(widget.value);
        _setInvalid(false);
      }
      return;
    }
    final parsed = widget.decimal ? double.tryParse(text) : int.tryParse(text);
    if (parsed == null || parsed < widget.min || parsed > widget.max) {
      _setInvalid(true);
      SemanticsService.sendAnnouncement(
        View.of(context),
        widget.invalidMessage,
        Directionality.of(context),
      );
      return;
    }
    _setInvalid(false);
    if (parsed != widget.value && parsed != _sent) {
      _sent = parsed;
      widget.onCommitted(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.emphasized
        ? context.textStyles.titleLarge
        : context.textStyles.titleMedium;
    return Semantics(
      label: widget.semanticLabel,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        style: style?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
        textInputAction: TextInputAction.next,
        inputFormatters: [
          widget.decimal
              ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              : FilteringTextInputFormatter.digitsOnly,
        ],
        onSubmitted: (_) => _commit(),
        onTapOutside: (_) => _focus.unfocus(),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: TokensSpacing.xs,
            vertical: TokensSpacing.sm,
          ),
          constraints: const BoxConstraints(
            minHeight: TokensLayout.minTouchTarget,
          ),
          // Borde rojo sin texto debajo: el mensaje va bajo la tabla.
          error: _invalid ? const SizedBox.shrink() : null,
        ),
      ),
    );
  }
}
