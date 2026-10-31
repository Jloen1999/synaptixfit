import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/screens/academic/widgets/markdown_toolbar.dart';

void main() {
  TextEditingController controller(String text, int start, [int? end]) =>
      TextEditingController(text: text)
        ..selection = TextSelection(
          baseOffset: start,
          extentOffset: end ?? start,
        );

  test('negrita envuelve lo seleccionado y la quita si ya la tiene', () {
    final c = controller('hola mundo', 5, 10);
    MarkdownEditing(c).wrap('**');
    expect(c.text, 'hola **mundo**');
    MarkdownEditing(c).wrap('**');
    expect(c.text, 'hola mundo');
  });

  test('sin selección deja el cursor entre los marcadores', () {
    final c = controller('', 0);
    MarkdownEditing(c).wrap('_');
    expect(c.text, '__');
    expect(c.selection.baseOffset, 1);
  });

  test('las listas se ponen y se quitan en todas las líneas elegidas', () {
    final c = controller('uno\ndos', 0, 7);
    MarkdownEditing(c).toggleLinePrefix('- ');
    expect(c.text, '- uno\n- dos');
    c.selection = const TextSelection(baseOffset: 0, extentOffset: 11);
    MarkdownEditing(c).toggleNumbered();
    expect(c.text, '1. uno\n2. dos');
  });

  test('el título cambia de nivel y vuelve a texto normal', () {
    final c = controller('Tema 1', 0);
    final edit = MarkdownEditing(c);
    edit.cycleHeading();
    expect(c.text, '# Tema 1');
    c.selection = const TextSelection.collapsed(offset: 0);
    edit.cycleHeading();
    c.selection = const TextSelection.collapsed(offset: 0);
    edit.cycleHeading();
    expect(c.text, '### Tema 1');
    c.selection = const TextSelection.collapsed(offset: 0);
    edit.cycleHeading();
    expect(c.text, 'Tema 1');
  });
}
