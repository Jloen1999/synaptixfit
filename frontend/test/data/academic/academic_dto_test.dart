import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/academic/dto/material_dtos.dart';
import 'package:synaptixfit/data/remote_data_source/academic/dto/note_dtos.dart';
import 'package:synaptixfit/data/remote_data_source/academic/dto/quiz_dtos.dart';
import 'package:synaptixfit/data/remote_data_source/academic/dto/study_dtos.dart';
import 'package:synaptixfit/data/remote_data_source/academic/dto/subject_dtos.dart';
import 'package:synaptixfit/domain/enums/ai_document_type.dart';
import 'package:synaptixfit/domain/enums/mastery_state.dart';
import 'package:synaptixfit/domain/enums/question_type.dart';
import 'package:synaptixfit/domain/enums/study_source_type.dart';
import 'package:synaptixfit/domain/enums/subject_priority.dart';
import 'package:synaptixfit/domain/enums/subject_timeline_type.dart';
import 'package:synaptixfit/domain/enums/test_session_status.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/academic/mind_map.dart';
import 'package:synaptixfit/domain/models/academic/study_artifact.dart';

void main() {
  test('SubjectDto mapea enums y pasa los instantes a hora local', () {
    final subject = SubjectDto.fromJson({
      'id': 's1',
      'name': 'Cálculo',
      'credits': 6,
      'perceivedDifficulty': 4,
      'priority': 'HIGH',
      'nextAssessmentAt': '2026-11-02T09:00:00Z',
      'archived': false,
      'noteCount': 3,
      'fileCount': 1,
    }).toDomain();

    expect(subject.priority, SubjectPriority.high);
    expect(subject.noteCount, 3);
    expect(subject.nextAssessmentAt!.isUtc, isFalse);
    expect(subject.nextAssessmentAt, DateTime.utc(2026, 11, 2, 9).toLocal());
  });

  test('SubjectTimelineItemDto distingue bloques y entregas', () {
    final exam = SubjectTimelineItemDto.fromJson({
      'id': 'd1',
      'kind': 'DEADLINE',
      'deadlineType': 'EXAM',
      'title': 'Parcial',
      'start': '2026-11-02T09:00:00Z',
    }).toDomain();
    final block = SubjectTimelineItemDto.fromJson({
      'id': 'b1',
      'kind': 'BLOCK',
      'blockType': 'CLASS',
      'title': 'Clase',
      'start': '2026-11-02T09:00:00Z',
      'completed': true,
    }).toDomain();

    expect(exam.type, SubjectTimelineType.exam);
    expect(exam.isDeadline, isTrue);
    expect(block.type, SubjectTimelineType.classSession);
    expect(block.isDeadline, isFalse);
    expect(block.completed, isTrue);
  });

  test('NoteDto tolera contenido nulo y mapea la visibilidad', () {
    final note = NoteDto.fromJson({
      'id': 'n1',
      'title': 'Tema 1',
      'visibility': 'FRIENDS',
      'quickNote': true,
    }).toDomain();

    expect(note.content, '');
    expect(note.visibility, Visibility.friends);
    expect(note.quickNote, isTrue);
  });

  test('SharedNotePageDto calcula si hay más páginas', () {
    final page = SharedNotePageDto.fromJson({
      'items': [
        {'id': 'n1', 'authorId': 'u1', 'authorName': 'Ana', 'title': 'T'},
      ],
      'page': 0,
      'totalPages': 2,
    }).toDomain();

    expect(page.items.single.authorName, 'Ana');
    expect(page.hasMore, isTrue);
  });

  test('StudyDocumentDto mapea el mapa mental anidado', () {
    final doc = StudyDocumentDto.fromJson({
      'id': 'd1',
      'sourceType': 'FILE',
      'sourceId': 'f1',
      'type': 'MIND_MAP',
      'mindMap': {
        'central': 'Derivadas',
        'branches': [
          {
            'title': 'Reglas',
            'children': [
              {'title': 'Cadena'},
            ],
          },
        ],
      },
    }).toDomain();

    expect(doc.sourceType, StudySourceType.file);
    expect(doc.type, AiDocumentType.mindMap);
    expect(
      doc.mindMap,
      const MindMap(
        central: 'Derivadas',
        branches: [
          MindMapNode(
            title: 'Reglas',
            children: [MindMapNode(title: 'Cadena')],
          ),
        ],
      ),
    );
  });

  test('MindMapDto.body y QuestionDraftDto.body serializan para la API', () {
    expect(
      MindMapDto.body(
        const MindMap(
          central: 'C',
          branches: [MindMapNode(title: 'R')],
        ),
      ),
      {
        'central': 'C',
        'branches': [
          {'title': 'R', 'children': <Object>[]},
        ],
      },
    );
    expect(
      QuestionDraftDto.body(
        const QuestionDraft(
          type: QuestionType.fillInBlank,
          statement: 'P',
          correctAnswer: 'R',
        ),
      ),
      {
        'type': 'FILL_IN_BLANK',
        'statement': 'P',
        'options': <String>[],
        'correctAnswer': 'R',
      },
    );
  });

  test('ReviewPreviewDto ordena las opciones de 0 a 5', () {
    final preview = ReviewPreviewDto.fromJson({
      'loadToday': 1.5,
      'maxDailyLoad': 4,
      'options': [
        {'quality': 5, 'intervalDays': 6, 'resultingState': 'MASTERED'},
        {'quality': 0, 'intervalDays': 1, 'resultingState': 'NEEDS_REVIEW'},
      ],
    }).toDomain();

    expect(preview.options.map((o) => o.quality), [0, 5]);
    expect(preview.options.first.resultingState, MasteryState.needsReview);
  });

  test('ReviewResponseDto incluye la XP del repaso', () {
    Map<String, dynamic> body({int? xp}) => {
      'material': {'id': 'm1', 'originId': 'n1', 'title': 'Tema 1'},
      'xpAwarded': ?xp,
    };
    expect(ReviewResponseDto.fromJson(body(xp: 5)).toDomain().xpAwarded, 5);
    expect(ReviewResponseDto.fromJson(body()).toDomain().xpAwarded, 0);
  });

  test('QuestionBankDto ordena las preguntas por su orden', () {
    final bank = QuestionBankDto.fromJson({
      'id': 'b1',
      'materialId': 'm1',
      'questions': [
        {'id': 'q2', 'type': 'FILL_IN_BLANK', 'statement': 'B', 'order': 2},
        {
          'id': 'q1',
          'type': 'MULTIPLE_CHOICE',
          'statement': 'A',
          'order': 1,
          'options': ['x', 'y'],
          'correctAnswer': 'x',
        },
      ],
    }).toDomain();

    expect(bank.questions.map((q) => q.id), ['q1', 'q2']);
    expect(bank.questions.first.type, QuestionType.multipleChoice);
  });

  test('TestSessionDto mapea estado y preguntas sin solución', () {
    final session = TestSessionDto.fromJson({
      'id': 't1',
      'materialId': 'm1',
      'status': 'COMPLETED',
      'score': 3,
      'totalQuestions': 4,
      'startedAt': '2026-10-01T10:00:00Z',
      'xpGranted': 15,
      'questions': [
        {
          'id': 'q1',
          'type': 'MULTIPLE_CHOICE',
          'statement': 'A',
          'answered': false,
        },
      ],
    }).toDomain();

    expect(session.status, TestSessionStatus.completed);
    expect(session.inProgress, isFalse);
    expect(session.xpGranted, 15);
    expect(session.questions.single.correctAnswer, isNull);
  });
}
