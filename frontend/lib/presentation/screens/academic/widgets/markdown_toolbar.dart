import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';

/// Barra de formato del editor de apuntes: aplica Markdown sobre lo
/// seleccionado (o en la posición del cursor) en [controller]. Los apuntes se
/// guardan en Markdown y la vista previa los pinta con `AcademicMarkdown`.
///
/// Atajos de teclado: Ctrl/Cmd+B negrita, Ctrl/Cmd+I cursiva.
class MarkdownToolbar extends StatelessWidget {
  const MarkdownToolbar({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final edit = MarkdownEditing(controller);
    final actions = <(IconData, String, VoidCallback)>[
      (Icons.title_rounded, l10n.academicFormatHeading, edit.cycleHeading),
      (
        Icons.format_bold_rounded,
        l10n.academicFormatShortcut(l10n.academicFormatBold, 'B'),
        () => edit.wrap('**'),
      ),
      (
        Icons.format_italic_rounded,
        l10n.academicFormatShortcut(l10n.academicFormatItalic, 'I'),
        () => edit.wrap('_'),
      ),
      (
        Icons.format_strikethrough_rounded,
        l10n.academicFormatStrike,
        () => edit.wrap('~~'),
      ),
      (
        Icons.format_list_bulleted_rounded,
        l10n.academicFormatBullets,
        () => edit.toggleLinePrefix('- '),
      ),
      (
        Icons.format_list_numbered_rounded,
        l10n.academicFormatNumbers,
        edit.toggleNumbered,
      ),
      (
        Icons.checklist_rounded,
        l10n.academicFormatChecklist,
        () => edit.toggleLinePrefix('- [ ] '),
      ),
      (
        Icons.format_quote_rounded,
        l10n.academicFormatQuote,
        () => edit.toggleLinePrefix('> '),
      ),
      (Icons.code_rounded, l10n.academicFormatCode, () => edit.wrap('`')),
      (
        Icons.horizontal_rule_rounded,
        l10n.academicFormatDivider,
        edit.insertDivider,
      ),
    ];
    // Dentro de la región del campo: en web y escritorio, pulsar la barra no
    // le quita el foco (se sigue escribiendo donde estaba el cursor).
    final bar = Material(
      color: context.colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(TokensRadius.m),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.xs),
        child: Row(
          children: [
            for (final (icon, label, onPressed) in actions)
              IconButton(
                tooltip: label,
                icon: Icon(icon),
                onPressed: onPressed,
              ),
          ],
        ),
      ),
    );
    return TextFieldTapRegion(
      child: Semantics(
        container: true,
        label: l10n.academicFormatToolbar,
        child: bar,
      ),
    );
  }
}

/// Atajos Ctrl/Cmd+B e I para el campo del apunte.
class MarkdownShortcuts extends StatelessWidget {
  const MarkdownShortcuts({
    super.key,
    required this.controller,
    required this.child,
  });

  final TextEditingController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final edit = MarkdownEditing(controller);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            edit.wrap('**'),
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            edit.wrap('**'),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            edit.wrap('_'),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
            edit.wrap('_'),
      },
      child: child,
    );
  }
}

/// Operaciones de formato sobre el texto y la selección de un controlador.
/// Sin estado propio: se puede crear en cada uso.
class MarkdownEditing {
  const MarkdownEditing(this.controller);

  final TextEditingController controller;

  TextSelection get _selection {
    final s = controller.selection;
    return s.isValid
        ? s
        : TextSelection.collapsed(offset: controller.text.length);
  }

  /// Envuelve lo seleccionado con [marker] (o lo quita si ya lo tiene); sin
  /// selección, deja el cursor entre los dos marcadores.
  void wrap(String marker) {
    final text = controller.text;
    final sel = _selection;
    final selected = sel.textInside(text);
    final before = sel.textBefore(text);
    final after = sel.textAfter(text);
    if (before.endsWith(marker) && after.startsWith(marker)) {
      controller.value = TextEditingValue(
        text:
            before.substring(0, before.length - marker.length) +
            selected +
            after.substring(marker.length),
        selection: TextSelection(
          baseOffset: sel.start - marker.length,
          extentOffset: sel.end - marker.length,
        ),
      );
      return;
    }
    controller.value = TextEditingValue(
      text: '$before$marker$selected$marker$after',
      selection: selected.isEmpty
          ? TextSelection.collapsed(offset: sel.start + marker.length)
          : TextSelection(
              baseOffset: sel.start + marker.length,
              extentOffset: sel.end + marker.length,
            ),
    );
  }

  /// Pone o quita [prefix] al principio de cada línea seleccionada.
  void toggleLinePrefix(String prefix) => _mapLines((lines) {
    final all = lines.every((l) => l.startsWith(prefix));
    return [
      for (final l in lines)
        all ? l.substring(prefix.length) : '$prefix${_stripListMarker(l)}',
    ];
  });

  /// Lista numerada (1., 2., …) sobre las líneas seleccionadas, o la quita.
  void toggleNumbered() => _mapLines((lines) {
    final numbered = RegExp(r'^\d+\. ');
    final all = lines.every(numbered.hasMatch);
    return [
      for (final (i, l) in lines.indexed)
        all ? l.replaceFirst(numbered, '') : '${i + 1}. ${_stripListMarker(l)}',
    ];
  });

  /// Sin título → # → ## → ### → sin título, en la línea del cursor.
  void cycleHeading() => _mapLines((lines) {
    final heading = RegExp(r'^(#{1,3}) ');
    return [
      for (final l in lines)
        switch (heading.firstMatch(l)?.group(1)?.length) {
          null => '# $l',
          3 => l.replaceFirst(heading, ''),
          final n => '${'#' * (n + 1)} ${l.replaceFirst(heading, '')}',
        },
    ];
  });

  /// Línea separadora en una línea propia.
  void insertDivider() {
    final text = controller.text;
    final sel = _selection;
    final before = sel.textBefore(text);
    final lead = before.isEmpty || before.endsWith('\n') ? '' : '\n';
    final insert = '$lead\n---\n';
    controller.value = TextEditingValue(
      text: before + insert + sel.textAfter(text),
      selection: TextSelection.collapsed(offset: sel.start + insert.length),
    );
  }

  static String _stripListMarker(String line) =>
      line.replaceFirst(RegExp(r'^(- \[[ xX]\] |- |\d+\. |> )'), '');

  /// Aplica [transform] a las líneas completas que toca la selección.
  void _mapLines(List<String> Function(List<String> lines) transform) {
    final text = controller.text;
    final sel = _selection;
    final start = sel.start == 0
        ? 0
        : text.lastIndexOf('\n', sel.start - 1) + 1;
    var end = text.indexOf('\n', sel.end);
    if (end < 0) end = text.length;
    final lines = text.substring(start, end).split('\n');
    final replaced = transform(lines).join('\n');
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, replaced),
      selection: TextSelection.collapsed(offset: start + replaced.length),
    );
  }
}
