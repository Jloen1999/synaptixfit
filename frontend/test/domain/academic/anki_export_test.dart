import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/models/academic/anki_export.dart';

void main() {
  test('cabeceras de Anki y una tarjeta por línea separada por tabulador', () {
    final text = AnkiExport.text('Álgebra  lineal', [
      ('¿Qué es una matriz?', 'Una tabla de números'),
      ('Cita "famosa"', 'Línea 1\nLínea 2'),
      ('#1 de la lista', 'Retorno\rsuelto'),
    ]);

    expect(
      text,
      '#separator:tab\n'
      '#html:false\n'
      '#deck:Álgebra lineal\n'
      '#tags:synaptixfit\n'
      '¿Qué es una matriz?\tUna tabla de números\n'
      '"Cita ""famosa"""\t"Línea 1\nLínea 2"\n'
      '"#1 de la lista"\t"Retorno\rsuelto"\n',
    );
  });

  test('el fichero se llama como el mazo, sin acentos ni símbolos', () {
    expect(
      AnkiExport.fileName('Álgebra lineal: tema 2'),
      'synaptixfit-algebra-lineal-tema-2.txt',
    );
    expect(AnkiExport.fileName('¿?'), 'synaptixfit.txt');
  });
}
