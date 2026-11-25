import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/academic/dto/note_sharing_dtos.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';

/// Respuestas de «Compartir» y de la disponibilidad por asignatura (ADR 0064).
void main() {
  test('lee el envío a un amigo y la publicación en el muro', () {
    final sent = SentNoteDto.fromJson({'friendId': 'u2', 'friendName': 'Bea'});
    expect(sent.toDomain().friendName, 'Bea');
    final wall = WallShareDto.fromJson({
      'alreadyShared': true,
      'visibility': 'FRIENDS',
    }).toDomain();
    expect(wall.alreadyShared, isTrue);
    expect(wall.visibility, Visibility.friends);
  });

  test('lee los documentos de cada fuente', () {
    final d = SourceDocumentsDto.fromJson({
      'sourceType': 'FILE',
      'sourceId': 'f1',
      'summary': true,
      'mindMap': false,
      'practice': true,
    });
    expect(d.sourceId, 'f1');
    expect(d.toDomain().summary, isTrue);
    expect(d.toDomain().mindMap, isFalse);
  });

  test('el nombre del PDF sale de Content-Disposition, con acentos', () {
    expect(
      fileNameFromDisposition(
        'attachment; filename="=?UTF-8?Q?Normalizaci=C3=B3n.pdf?="; '
        "filename*=UTF-8''Normalizaci%C3%B3n.pdf",
        'apunte.pdf',
      ),
      'Normalización.pdf',
    );
    expect(
      fileNameFromDisposition('attachment; filename="Tema 1.pdf"', 'x.pdf'),
      'Tema 1.pdf',
    );
    expect(fileNameFromDisposition(null, 'apunte.pdf'), 'apunte.pdf');
  });
}
