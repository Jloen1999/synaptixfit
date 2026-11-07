import 'dart:async';

import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Buscador único de la app (ADR 0036): el mismo en Académico, ejercicios,
/// retos, rutinas de la comunidad y apuntes compartidos. Lupa, botón para
/// borrar lo escrito y, si se da [debounce], espera a que se deje de teclear
/// antes de avisar (para no pedir al servidor una búsqueda por letra).
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.label,
    required this.onChanged,
    this.controller,
    this.debounce = Duration.zero,
    this.autofocus = false,
    this.onSubmitted,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final Duration debounce;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  /// Espera habitual cuando la búsqueda va al servidor.
  static const serverDebounce = Duration(milliseconds: 350);

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  TextEditingController? _own;
  Timer? _timer;

  /// Al borrar con el aspa, el botón desaparece: el foco vuelve al campo en
  /// vez de perderse (WCAG 2.4.3).
  final _focus = FocusNode();

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  void _changed(String value) {
    _timer?.cancel();
    if (widget.debounce == Duration.zero) {
      widget.onChanged(value);
      return;
    }
    _timer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    widget.onChanged('');
    _focus.requestFocus();
  }

  /// Intro o la lupa del teclado buscan ya, sin esperar.
  void _submitted(String value) {
    _timer?.cancel();
    widget.onChanged(value);
    widget.onSubmitted?.call(value);
  }

  @override
  void dispose() {
    _focus.dispose();
    _timer?.cancel();
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => TextField(
        controller: _controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        onChanged: _changed,
        onSubmitted: _submitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.commonSearchClear,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clear,
                ),
        ),
      ),
    );
  }
}

/// Texto con lo buscado resaltado (sin distinguir mayúsculas ni tildes:
/// «fisica» resalta «Física»), como en los resultados del buscador.
class AppHighlightedText extends StatelessWidget {
  const AppHighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.maxLines = 2,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int maxLines;

  /// Minúsculas y sin tildes, letra a letra (mismo largo que el original para
  /// poder recortar por posición).
  static String fold(String text) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
    const to = 'aaaaaeeeeiiiiooooouuuuncaaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final char in text.split('')) {
      final i = from.indexOf(char);
      buffer.write(i < 0 ? char.toLowerCase() : to[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final needle = fold(query.trim());
    final haystack = fold(text);
    final at = needle.isEmpty ? -1 : haystack.indexOf(needle);
    if (at < 0 || haystack.length != text.length) {
      return Text(
        text,
        style: base,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }
    final end = at + needle.length;
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: text.substring(at, end),
            style: base.copyWith(
              fontWeight: FontWeight.w800,
              backgroundColor: context.colors.tertiaryContainer,
              color: context.colors.onTertiaryContainer,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Estado vacío de una búsqueda: «No hay resultados para "x"» y, si se da,
/// una acción útil («Crear apunte "x"»).
class AppSearchEmpty extends StatelessWidget {
  const AppSearchEmpty({
    super.key,
    required this.query,
    this.actionLabel,
    this.onAction,
  });

  final String query;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Padding(
      padding: const EdgeInsets.all(TokensSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: TokensSize.iconL,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: TokensSpacing.s),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.commonSearchNoResults(query.trim()),
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: TokensSpacing.m),
            FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
