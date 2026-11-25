import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';

/// `CalendarBlock.onlineLink` y `locationShown` (ADR 0065): el enlace de una
/// clase en línea sale de «Lugar» y a la vista se enseña solo su dominio.
void main() {
  CalendarBlock at(String? location) => CalendarBlock(
    id: 'b1',
    type: BlockType.classSession,
    start: DateTime(2025, 10, 15, 9),
    end: DateTime(2025, 10, 15, 11),
    location: location,
  );

  test('el enlace https sale del «Lugar», sin la puntuación que lo cierra', () {
    expect(
      at('Teams: https://teams.example.com/l/abc?x=1 (clave 12)').onlineLink,
      Uri.parse('https://teams.example.com/l/abc?x=1'),
    );
    expect(
      at('(https://meet.example.com/abc-defg).').onlineLink,
      Uri.parse('https://meet.example.com/abc-defg'),
    );
    expect(
      at('Zoom <https://zoom.example.com/j/1>;').onlineLink,
      Uri.parse('https://zoom.example.com/j/1'),
    );
  });

  test('un aula, un http sin cifrar o nada no son enlace', () {
    expect(at('Aula 2.4').onlineLink, isNull);
    expect(at('http://inseguro.example.com').onlineLink, isNull);
    expect(at('https://').onlineLink, isNull);
    expect(at(null).onlineLink, isNull);
  });

  test('a la vista, el enlace se cambia por su dominio', () {
    expect(
      at('Teams: (https://teams.microsoft.com/l/abc).').locationShown,
      'Teams: (teams.microsoft.com).',
    );
    expect(at('  Aula 2.4 ').locationShown, 'Aula 2.4');
    expect(at(null).locationShown, isNull);
  });
}
