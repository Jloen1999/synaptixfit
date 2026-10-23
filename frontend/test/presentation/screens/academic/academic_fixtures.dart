import 'package:synaptixfit/domain/enums/ai_document_type.dart';
import 'package:synaptixfit/domain/enums/artifact_kind.dart';
import 'package:synaptixfit/domain/enums/mastery_state.dart';
import 'package:synaptixfit/domain/enums/question_type.dart';
import 'package:synaptixfit/domain/enums/study_source_type.dart';
import 'package:synaptixfit/domain/enums/subject_priority.dart';
import 'package:synaptixfit/domain/enums/syllabus_topic_kind.dart';
import 'package:synaptixfit/domain/enums/test_session_status.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/academic/note.dart';
import 'package:synaptixfit/domain/models/academic/quiz.dart';
import 'package:synaptixfit/domain/models/academic/study_artifact.dart';
import 'package:synaptixfit/domain/models/academic/study_document.dart';
import 'package:synaptixfit/domain/models/academic/study_material.dart';
import 'package:synaptixfit/domain/models/academic/subject.dart';
import 'package:synaptixfit/domain/models/academic/subject_file.dart';
import 'package:synaptixfit/domain/models/academic/teaching_guide.dart';
import 'package:synaptixfit/domain/models/account/account.dart';

/// Datos de prueba compartidos por los tests del módulo academic.
const subject = Subject(
  id: 's1',
  name: 'Cálculo',
  credits: 6,
  perceivedDifficulty: 3,
  priority: SubjectPriority.high,
  archived: false,
  noteCount: 2,
  fileCount: 1,
);

const note = Note(
  id: 'n1',
  subjectId: 's1',
  title: 'Límites',
  content: '# Límites',
  visibility: Visibility.private,
  quickNote: false,
);

const file = SubjectFile(
  id: 'f1',
  subjectId: 's1',
  fileName: 'guia.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 1000,
  aiReadable: true,
);

const guide = TeachingGuide(
  subjectId: 's1',
  topics: [
    SyllabusTopic(
      index: 0,
      title: 'Tema 1',
      kind: SyllabusTopicKind.theory,
      completed: false,
    ),
  ],
  assessments: [Assessment(index: 0, name: 'Examen', percentage: 60)],
  syllabusProgress: 0,
);

const retention = Retention(
  mastered: 1,
  inProgress: 1,
  needsReview: 0,
  notEvaluated: 0,
  abandoned: 0,
  total: 2,
);

const material = StudyMaterial(
  id: 'm1',
  subjectId: 's1',
  originType: StudySourceType.note,
  originId: 'n1',
  title: 'Límites',
  masteryState: MasteryState.inProgress,
  intervalDays: 1,
  easeFactor: 2.5,
  completedReviews: 1,
  failedReviews: 0,
);

const preview = ReviewPreview(
  loadToday: 1,
  maxDailyLoad: 4,
  fatigueCoefficient: 0.1,
  options: [
    ReviewOption(
      quality: 5,
      adjustedQuality: 4.9,
      intervalDays: 6,
      resultingState: MasteryState.mastered,
    ),
  ],
);

const question1 = Question(
  id: 'q1',
  type: QuestionType.multipleChoice,
  statement: '¿2+2?',
  options: ['3', '4'],
  order: 0,
  correctAnswer: '4',
);

const question2 = Question(
  id: 'q2',
  type: QuestionType.fillInBlank,
  statement: 'Capital de Francia',
  order: 1,
  correctAnswer: 'París',
);

const bank = QuestionBank(
  id: 'b1',
  materialId: 'm1',
  xpAwarded: false,
  attemptedQuestions: 0,
  correctQuestions: 0,
  questions: [question1, question2],
);

final session = TestSession(
  id: 't1',
  materialId: 'm1',
  status: TestSessionStatus.inProgress,
  currentIndex: 0,
  score: 0,
  totalQuestions: 2,
  answeredCount: 0,
  startedAt: DateTime(2026, 10, 1, 10),
  xpAwarded: false,
  xpGranted: 0,
  questions: const [
    SessionQuestion(
      id: 'q1',
      type: QuestionType.multipleChoice,
      statement: '¿2+2?',
      options: ['3', '4'],
      answered: false,
    ),
    SessionQuestion(
      id: 'q2',
      type: QuestionType.fillInBlank,
      statement: 'Capital de Francia',
      answered: false,
    ),
  ],
);

const summaryDoc = StudyDocument(
  id: 'd1',
  sourceType: StudySourceType.note,
  sourceId: 'n1',
  type: AiDocumentType.summary,
  markdown: 'Resumen',
);

const artifact = StudyArtifact(
  kind: ArtifactKind.flashcards,
  title: 'Tarjetas',
  flashcards: [Flashcard(question: 'P', answer: 'R')],
);

const account = Account(
  id: 'u1',
  email: 'a@b.co',
  fullName: 'Ana',
  level: 2,
  levelXp: 30,
  levelThreshold: 200,
  streak: 1,
  privacy: Visibility.private,
  role: UserRole.user,
  hasPassword: true,
  googleLinked: false,
);
