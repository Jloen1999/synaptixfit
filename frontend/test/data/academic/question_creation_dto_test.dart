import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/academic/dto/question_creation_dtos.dart';
import 'package:synaptixfit/data/remote_data_source/academic/dto/quiz_dtos.dart';
import 'package:synaptixfit/domain/enums/question_creation_enums.dart';
import 'package:synaptixfit/domain/enums/question_type.dart';
import 'package:synaptixfit/domain/models/academic/question_creation.dart';

/// «Crear preguntas» y «Varias correctas» en la API (ADR 0058).
void main() {
  test('las preguntas del documento llegan con su estado', () {
    final scan = DocumentQuestionScanDto.fromJson({
      'complete': false,
      'questions': [
        {
          'type': 'MULTIPLE_ANSWER',
          'statement': '¿Cuáles agregan?',
          'options': ['SUM', 'JOIN', 'AVG'],
          'correctAnswers': ['SUM', 'AVG'],
          'status': 'ANSWER_PROPOSED',
        },
        {'type': null, 'statement': 'Explica…', 'status': 'LONG_ANSWER'},
      ],
    }).toDomain();

    expect(scan.complete, isFalse);
    expect(scan.questions.first.type, QuestionType.multipleAnswer);
    expect(scan.questions.first.usable, isTrue);
    expect(scan.questions.last.status, DocumentQuestionStatus.longAnswer);
    expect(scan.questions.last.usable, isFalse);
  });

  test('la petición manda formato, nuevas, modo y las del documento', () {
    final json = CreateQuestionsRequestDto.from(
      const CreateQuestionsRequest(
        format: QuestionFormat.flashcard,
        newQuestions: 5,
        mode: BankUpdateMode.replace,
        documentQuestions: [
          DocumentQuestion(
            type: QuestionType.multipleChoice,
            statement: '¿Qué filtra grupos?',
            options: ['WHERE', 'HAVING'],
            correctAnswers: ['HAVING'],
            status: DocumentQuestionStatus.ready,
          ),
        ],
      ),
    ).toJson();

    expect(json['format'], 'FLASHCARD');
    expect(json['newQuestions'], 5);
    expect(json['mode'], 'REPLACE');
    expect((json['documentQuestions'] as List).single, {
      'type': 'MULTIPLE_CHOICE',
      'statement': '¿Qué filtra grupos?',
      'options': ['WHERE', 'HAVING'],
      'correctAnswers': ['HAVING'],
    });
  });

  test(
    'varias correctas: lista de correctas y, de versiones viejas, la única',
    () {
      final multi = QuestionDto.fromJson({
        'id': 'q1',
        'type': 'MULTIPLE_ANSWER',
        'statement': '¿Cuáles?',
        'options': ['A', 'B', 'C'],
        'correctAnswer': 'A · C',
        'correctAnswers': ['A', 'C'],
      }).toDomain();
      final old = QuestionDto.fromJson({
        'id': 'q2',
        'type': 'MULTIPLE_CHOICE',
        'statement': '¿Una?',
        'options': ['A', 'B'],
        'correctAnswer': 'B',
      }).toDomain();

      expect(multi.correctAnswers, ['A', 'C']);
      expect(old.correctAnswers, ['B']);
    },
  );

  test('las respuestas elegidas viajan unidas por salto de línea', () {
    final joined = QuestionAnswers.join([' A ', '', 'C']);
    expect(joined, 'A\nC');
    expect(QuestionAnswers.split(joined), ['A', 'C']);
    expect(QuestionAnswers.split(null), isEmpty);
  });

  test('nuevas que faltan según lo que se usa del documento', () {
    expect(
      QuestionCount.newQuestions(
        use: DocumentQuestionUse.mix,
        total: 10,
        fromDocument: 6,
      ),
      4,
    );
    expect(
      QuestionCount.newQuestions(
        use: DocumentQuestionUse.mix,
        total: 10,
        fromDocument: 12,
      ),
      0,
    );
    expect(
      QuestionCount.newQuestions(
        use: DocumentQuestionUse.only,
        total: 10,
        fromDocument: 3,
      ),
      0,
    );
    expect(
      QuestionCount.newQuestions(
        use: DocumentQuestionUse.none,
        total: 15,
        fromDocument: 3,
      ),
      15,
    );
  });
}
