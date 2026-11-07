import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/enums/ai_document_type.dart';
import '../../../domain/enums/study_source_type.dart';
import 'academic_home/page/academic_home_page.dart';
import 'academic_search/page/academic_search_page.dart';
import 'ai_document/page/ai_document_page.dart';
import 'file_viewer/page/file_viewer_page.dart';
import 'flashcards/page/flashcards_page.dart';
import 'free_practice/page/free_practice_page.dart';
import 'generation_center/page/generation_center_page.dart';
import 'material_review/page/material_review_page.dart';
import 'mock_exam/page/mock_exam_page.dart';
import 'mock_exam_setup/page/mock_exam_setup_page.dart';
import 'note_editor/page/note_editor_page.dart';
import 'note_scan/page/note_scan_page.dart';
import 'note_viewer/page/note_viewer_page.dart';
import 'practice_hub/page/practice_hub_page.dart';
import 'shared_note_detail/page/shared_note_detail_page.dart';
import 'shared_notes/page/shared_notes_page.dart';
import 'subject_detail/page/subject_detail_page.dart';
import 'subject_form/page/subject_form_page.dart';
import 'teaching_guide_import/page/teaching_guide_import_page.dart';
import 'test_results/page/test_results_page.dart';

/// Rutas del módulo academic.
abstract final class AcademicPaths {
  static const root = '/academic';

  /// Académico con el filtro «Archivadas» puesto (el aviso de archivar
  /// lleva aquí).
  static const archived = '/academic?view=archived';
  static const newSubject = '/academic/subjects/new';

  /// Elegir asignaturas del plan de estudios: una sola pantalla, la del perfil
  /// (con buscador y filtros), para no tener dos que hacen lo mismo.
  static const catalog = '/profile/subjects';
  static const sharedNotes = '/academic/notes/shared';

  /// Apuntes compartidos de un autor (perfil público → «Ver todos»).
  static String sharedNotesBy(String authorId) =>
      _withQuery(sharedNotes, {'authorId': authorId});

  static String sharedNote(String noteId) => '/academic/notes/shared/$noteId';

  /// Importar el plan docente en PDF; con [subjectId] completa esa asignatura.
  static String importGuide({String? subjectId}) =>
      _withQuery('/academic/import-guide', {'subjectId': subjectId});

  /// Calendario semanal (módulo planner).
  static const planner = '/planner';

  /// Calendario abierto en el día de [start] con el bloque [blockId] abierto.
  static String plannerBlock(String blockId, DateTime start) =>
      _withQuery(planner, {
        'week':
            '${start.year.toString().padLeft(4, '0')}-'
            '${start.month.toString().padLeft(2, '0')}-'
            '${start.day.toString().padLeft(2, '0')}',
        'block': blockId,
      });

  /// Entregas y exámenes (módulo planner).
  static const deadlines = '/planner/deadlines';

  /// Una entrega concreta, destacada arriba en la lista de entregas.
  static String deadline(String id) =>
      Uri(path: deadlines, queryParameters: {'focus': id}).toString();

  /// Pomodoro (módulo planner) vinculado a una asignatura.
  static String pomodoro({required String subjectId, required String title}) =>
      _withQuery('/planner/pomodoro', {'subjectId': subjectId, 'title': title});

  static String subject(String subjectId) => '/academic/subjects/$subjectId';

  static String editSubject(String subjectId) =>
      '/academic/subjects/$subjectId/edit';

  /// Nuevo apunte; `quick` lo marca como nota rápida y `title` lo propone.
  static String newNote({
    String? subjectId,
    bool quick = false,
    String? title,
  }) => _withQuery('/academic/notes/new', {
    'subjectId': subjectId,
    if (quick) 'quick': '1',
    'title': title,
  });

  /// Buscador único de Académico (ADR 0036).
  static const search = '/academic/search';

  /// Fotografiar apuntes en papel y pasarlos a un apunte.
  static String scanNote({String? subjectId}) =>
      _withQuery('/academic/notes/scan', {'subjectId': subjectId});

  /// Preparar un simulacro con varios temas de la asignatura.
  static String subjectMockExam(String subjectId) =>
      '/academic/subjects/$subjectId/mock-exam';

  static String note(String noteId) => '/academic/notes/$noteId';

  static String editNote(String noteId) => '/academic/notes/$noteId/edit';

  static String file(String fileId) => '/academic/files/$fileId';

  /// Documento de IA (cargar o generar) sobre un apunte o archivo.
  static String aiDocument(
    StudySourceType sourceType,
    String sourceId,
    AiDocumentType type,
    String title,
  ) => _withQuery('/academic/ai/${sourceType.name}/$sourceId/${type.name}', {
    'title': title,
  });

  /// Centro de generación multi-fuente.
  static String generate({String? subjectId}) =>
      _withQuery('/academic/generate', {'subjectId': subjectId});

  /// Repaso de un material; [queue], los que vienen después («Repasar todos»).
  static String review(String materialId, {List<String> queue = const []}) =>
      '/academic/materials/$materialId/review'
      '${queue.isEmpty ? '' : '?queue=${queue.join(',')}'}';

  static String practice(String materialId) => '/academic/practice/$materialId';

  static String freePractice(String materialId) =>
      '/academic/practice/$materialId/free';

  static String flashcards(String materialId) =>
      '/academic/practice/$materialId/flashcards';

  /// Simulacro; `resume` reanuda la sesión en curso en lugar de crear otra.
  /// Con `withMaterials` mezcla preguntas de otros materiales (simulacro de
  /// asignatura) y `count` fija cuántas preguntas.
  static String exam(
    String materialId, {
    bool resume = false,
    List<String> withMaterials = const [],
    int? count,
  }) => _withQuery('/academic/practice/$materialId/exam', {
    if (resume) 'resume': '1',
    if (withMaterials.isNotEmpty) 'with': withMaterials.join(','),
    if (count != null) 'count': '$count',
  });

  static String testResults(String sessionId) =>
      '/academic/test-sessions/$sessionId/results';

  static String _withQuery(String path, Map<String, String?> query) {
    final params = {
      for (final e in query.entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    return Uri(
      path: path,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }
}

/// Rutas de otros módulos a las que navega este (se escriben como texto para no
/// depender de sus ficheros).
abstract final class AcademicExternalPaths {
  /// Perfil público de un usuario (módulo social).
  static String userProfile(String userId) => '/social/users/$userId';

  /// Buscar amigos y gestionar solicitudes (módulo social).
  static const friends = '/social/friends';

  /// Privacidad del perfil (módulo profile, «Editar cuenta»).
  static const privacySettings = '/profile/account';
}

/// Rutas dentro de la pestaña (conservan la barra inferior).
final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

List<RouteBase> academicBranchRoutes() => [
  GoRoute(
    path: AcademicPaths.root,
    builder: (context, state) {
      final archived = state.uri.queryParameters['view'] == 'archived';
      // La clave rehace la pantalla al llegar con otro filtro desde un aviso.
      return AcademicHomePage(key: ValueKey(archived), showArchived: archived);
    },
  ),
];

/// Rutas a pantalla completa (sin barra inferior). Las rutas fijas van antes
/// que las que tienen parámetros.
List<RouteBase> academicRoutes() => [
  GoRoute(
    path: AcademicPaths.newSubject,
    builder: (context, state) => const SubjectFormPage(),
  ),
  GoRoute(
    path: '/academic/import-guide',
    builder: (context, state) => TeachingGuideImportPage(
      subjectId: state.uri.queryParameters['subjectId'],
    ),
  ),
  GoRoute(
    path: '/academic/subjects/:subjectId/edit',
    builder: (context, state) =>
        SubjectFormPage(subjectId: state.pathParameters['subjectId']),
  ),
  GoRoute(
    path: '/academic/subjects/:subjectId/mock-exam',
    builder: (context, state) =>
        MockExamSetupPage(subjectId: state.pathParameters['subjectId']!),
  ),
  GoRoute(
    path: '/academic/subjects/:subjectId',
    builder: (context, state) =>
        SubjectDetailPage(subjectId: state.pathParameters['subjectId']!),
  ),
  GoRoute(
    path: '/academic/notes/scan',
    builder: (context, state) =>
        NoteScanPage(subjectId: state.uri.queryParameters['subjectId']),
  ),
  GoRoute(
    path: '/academic/notes/new',
    builder: (context, state) => NoteEditorPage(
      subjectId: state.uri.queryParameters['subjectId'],
      quickNote: state.uri.queryParameters['quick'] == '1',
      initialTitle: state.uri.queryParameters['title'],
    ),
  ),
  GoRoute(
    path: AcademicPaths.search,
    builder: (context, state) => const AcademicSearchPage(),
  ),
  GoRoute(
    path: AcademicPaths.sharedNotes,
    builder: (context, state) =>
        SharedNotesPage(authorId: state.uri.queryParameters['authorId']),
  ),
  GoRoute(
    path: '/academic/notes/shared/:noteId',
    builder: (context, state) =>
        SharedNoteDetailPage(noteId: state.pathParameters['noteId']!),
  ),
  GoRoute(
    path: '/academic/notes/:noteId/edit',
    builder: (context, state) =>
        NoteEditorPage(noteId: state.pathParameters['noteId']),
  ),
  GoRoute(
    path: '/academic/notes/:noteId',
    builder: (context, state) =>
        NoteViewerPage(noteId: state.pathParameters['noteId']!),
  ),
  GoRoute(
    path: '/academic/files/:fileId',
    builder: (context, state) =>
        FileViewerPage(fileId: state.pathParameters['fileId']!),
  ),
  GoRoute(
    path: '/academic/ai/:sourceType/:sourceId/:docType',
    builder: (context, state) => AiDocumentPage(
      sourceType: _byName(
        StudySourceType.values,
        state.pathParameters['sourceType'],
        StudySourceType.note,
      ),
      sourceId: state.pathParameters['sourceId']!,
      type: _byName(
        AiDocumentType.values,
        state.pathParameters['docType'],
        AiDocumentType.summary,
      ),
      title: state.uri.queryParameters['title'] ?? '',
    ),
  ),
  GoRoute(
    path: '/academic/generate',
    builder: (context, state) =>
        GenerationCenterPage(subjectId: state.uri.queryParameters['subjectId']),
  ),
  GoRoute(
    path: '/academic/materials/:materialId/review',
    builder: (context, state) => MaterialReviewPage(
      materialId: state.pathParameters['materialId']!,
      // La cola llega en la URL: solo se aceptan ids con forma de UUID.
      queue: [
        for (final id in (state.uri.queryParameters['queue'] ?? '').split(','))
          if (_uuid.hasMatch(id)) id,
      ],
    ),
  ),
  GoRoute(
    path: '/academic/practice/:materialId/free',
    builder: (context, state) =>
        FreePracticePage(materialId: state.pathParameters['materialId']!),
  ),
  GoRoute(
    path: '/academic/practice/:materialId/flashcards',
    builder: (context, state) =>
        FlashcardsPage(materialId: state.pathParameters['materialId']!),
  ),
  GoRoute(
    path: '/academic/practice/:materialId/exam',
    builder: (context, state) => MockExamPage(
      materialId: state.pathParameters['materialId']!,
      resume: state.uri.queryParameters['resume'] == '1',
      extraMaterialIds: [
        for (final id in (state.uri.queryParameters['with'] ?? '').split(','))
          if (_uuid.hasMatch(id)) id,
      ],
      questionCount: int.tryParse(state.uri.queryParameters['count'] ?? ''),
    ),
  ),
  GoRoute(
    path: '/academic/practice/:materialId',
    builder: (context, state) =>
        PracticeHubPage(materialId: state.pathParameters['materialId']!),
  ),
  GoRoute(
    path: '/academic/test-sessions/:sessionId/results',
    builder: (context, state) =>
        TestResultsPage(sessionId: state.pathParameters['sessionId']!),
  ),
];

T _byName<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;
