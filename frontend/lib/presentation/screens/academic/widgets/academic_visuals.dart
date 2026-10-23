import 'package:flutter/material.dart' hide Visibility;
import 'package:intl/intl.dart';

import '../../../../domain/enums/ai_document_type.dart';
import '../../../../domain/enums/artifact_kind.dart';
import '../../../../domain/enums/mastery_state.dart';
import '../../../../domain/enums/question_type.dart';
import '../../../../domain/enums/subject_priority.dart';
import '../../../../domain/enums/subject_timeline_type.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/academic/subject.dart';
import '../../../../domain/models/academic/subject_file.dart';
import '../../../extensions/context_extensions.dart';

/// Color de una asignatura derivado de su id (estable entre sesiones) a partir
/// de los colores del tema.
Color subjectColor(BuildContext context, String subjectId) {
  final palette = context.palette;
  final colors = context.colors;
  final options = [
    palette.study,
    palette.sessions,
    colors.secondary,
    palette.calories,
    colors.tertiary,
    palette.accent,
    palette.success,
    colors.primary,
  ];
  final hash = subjectId.codeUnits.fold<int>(
    0,
    (a, c) => (a * 31 + c) & 0x7fffffff,
  );
  return options[hash % options.length];
}

const _stopWords = {
  'de',
  'del',
  'la',
  'las',
  'el',
  'los',
  'y',
  'e',
  'en',
  'a',
  'al',
  'para',
  'por',
  'con',
  'i',
  'ii',
  'iii',
};

/// Siglas de una asignatura: su código o las iniciales de las palabras
/// significativas del nombre.
String subjectAcronym(Subject subject) {
  final code = subject.code?.trim();
  if (code != null && code.isNotEmpty && code.length <= 6) {
    return code.toUpperCase();
  }
  final words = subject.name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !_stopWords.contains(w.toLowerCase()))
      .toList();
  if (words.isEmpty) {
    return subject.name.characters.take(2).toString().toUpperCase();
  }
  if (words.length == 1) {
    return words.first.characters.take(3).toString().toUpperCase();
  }
  return words.take(4).map((w) => w.characters.first).join().toUpperCase();
}

/// Fecha corta en español («12 oct»).
String shortDate(DateTime date) => DateFormat('d MMM', 'es').format(date);

/// Fecha con hora en español («12 oct, 18:30»).
String dateTime(DateTime date) => DateFormat('d MMM, HH:mm', 'es').format(date);

/// Fecha larga en español («lunes, 12 de octubre»).
String longDate(DateTime date) =>
    DateFormat("EEEE, d 'de' MMMM", 'es').format(date);

/// Tamaño legible de un archivo.
String fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Nota con un decimal en formato español.
String grade(double value) => NumberFormat('0.0', 'es').format(value);

IconData fileIcon(SubjectFile file) {
  if (file.isPdf) return Icons.picture_as_pdf_rounded;
  if (file.isImage) return Icons.image_rounded;
  final mime = file.mimeType;
  if (mime.contains('presentation') || mime.contains('powerpoint')) {
    return Icons.slideshow_rounded;
  }
  if (mime.contains('sheet') || mime.contains('excel')) {
    return Icons.table_chart_rounded;
  }
  if (mime.contains('word') || mime.startsWith('text/')) {
    return Icons.description_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

IconData aiDocumentIcon(AiDocumentType type) => switch (type) {
  AiDocumentType.summary => Icons.summarize_rounded,
  AiDocumentType.mindMap => Icons.account_tree_rounded,
  AiDocumentType.practice => Icons.quiz_rounded,
  AiDocumentType.teachingGuide => Icons.menu_book_rounded,
};

IconData artifactIcon(ArtifactKind kind) => switch (kind) {
  ArtifactKind.summary => Icons.summarize_rounded,
  ArtifactKind.mindMap => Icons.account_tree_rounded,
  ArtifactKind.flashcards => Icons.style_rounded,
  ArtifactKind.practiceTest => Icons.quiz_rounded,
};

IconData timelineIcon(SubjectTimelineType type) => switch (type) {
  SubjectTimelineType.study => Icons.menu_book_rounded,
  SubjectTimelineType.classSession => Icons.co_present_rounded,
  SubjectTimelineType.review => Icons.replay_rounded,
  SubjectTimelineType.exam => Icons.assignment_late_rounded,
  SubjectTimelineType.assignment => Icons.assignment_turned_in_rounded,
  SubjectTimelineType.presentation => Icons.record_voice_over_rounded,
  SubjectTimelineType.other => Icons.event_rounded,
};

/// Textos y colores de los enums del módulo.
extension AcademicLabels on BuildContext {
  String masteryLabel(MasteryState state) {
    final l10n = localizations;
    return switch (state) {
      MasteryState.notEvaluated => l10n.academicMasteryNotEvaluated,
      MasteryState.inProgress => l10n.academicMasteryInProgress,
      MasteryState.mastered => l10n.academicMasteryMastered,
      MasteryState.needsReview => l10n.academicMasteryNeedsReview,
      MasteryState.abandoned => l10n.academicMasteryAbandoned,
    };
  }

  Color masteryColor(MasteryState state) => switch (state) {
    MasteryState.notEvaluated => colors.onSurfaceVariant,
    MasteryState.inProgress => palette.sessions,
    MasteryState.mastered => palette.success,
    MasteryState.needsReview => palette.warning,
    MasteryState.abandoned => colors.error,
  };

  String priorityLabel(SubjectPriority priority) {
    final l10n = localizations;
    return switch (priority) {
      SubjectPriority.low => l10n.academicPriorityLow,
      SubjectPriority.medium => l10n.academicPriorityMedium,
      SubjectPriority.high => l10n.academicPriorityHigh,
    };
  }

  String visibilityLabel(Visibility visibility) {
    final l10n = localizations;
    return switch (visibility) {
      Visibility.private => l10n.academicVisibilityPrivate,
      Visibility.friends => l10n.academicVisibilityFriends,
      Visibility.public => l10n.academicVisibilityPublic,
    };
  }

  IconData visibilityIcon(Visibility visibility) => switch (visibility) {
    Visibility.private => Icons.lock_outline_rounded,
    Visibility.friends => Icons.group_outlined,
    Visibility.public => Icons.public_rounded,
  };

  String aiDocumentLabel(AiDocumentType type) {
    final l10n = localizations;
    return switch (type) {
      AiDocumentType.summary => l10n.academicAiSummary,
      AiDocumentType.mindMap => l10n.academicAiMindMap,
      AiDocumentType.practice => l10n.academicAiPractice,
      AiDocumentType.teachingGuide => l10n.academicGuideTitle,
    };
  }

  String artifactLabel(ArtifactKind kind) {
    final l10n = localizations;
    return switch (kind) {
      ArtifactKind.summary => l10n.academicAiSummary,
      ArtifactKind.mindMap => l10n.academicAiMindMap,
      ArtifactKind.flashcards => l10n.academicFlashcardsTitle,
      ArtifactKind.practiceTest => l10n.academicGenerateKindTest,
    };
  }

  String questionTypeLabel(QuestionType type) {
    final l10n = localizations;
    return switch (type) {
      QuestionType.multipleChoice => l10n.academicQuestionMultipleChoice,
      QuestionType.fillInBlank => l10n.academicQuestionFillInBlank,
    };
  }

  String timelineLabel(SubjectTimelineType type) {
    final l10n = localizations;
    return switch (type) {
      SubjectTimelineType.study => l10n.academicTimelineStudy,
      SubjectTimelineType.classSession => l10n.academicTimelineClass,
      SubjectTimelineType.review => l10n.academicTimelineReview,
      SubjectTimelineType.exam => l10n.academicTimelineExam,
      SubjectTimelineType.assignment => l10n.academicTimelineAssignment,
      SubjectTimelineType.presentation => l10n.academicTimelinePresentation,
      SubjectTimelineType.other => l10n.academicTimelineOther,
    };
  }

  /// Texto de la autoevaluación SM-2 (0-5).
  String qualityLabel(int quality) {
    final l10n = localizations;
    return switch (quality) {
      0 => l10n.academicQuality0,
      1 => l10n.academicQuality1,
      2 => l10n.academicQuality2,
      3 => l10n.academicQuality3,
      4 => l10n.academicQuality4,
      _ => l10n.academicQuality5,
    };
  }
}

/// «OBLIGATORIA» → «Obligatoria». Un texto con mayúsculas normales se deja
/// igual (los planes docentes a veces escriben el carácter todo en mayúsculas).
String sentenceCase(String text) {
  final t = text.trim();
  if (t.isEmpty || t != t.toUpperCase()) return t;
  final lower = t.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}
