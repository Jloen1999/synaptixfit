import 'package:synaptixfit/domain/enums/admin/admin_erasure_mode.dart';
import 'package:synaptixfit/domain/enums/admin/admin_exercise_difficulty.dart';
import 'package:synaptixfit/domain/enums/admin/admin_exercise_modality.dart';
import 'package:synaptixfit/domain/enums/admin/admin_timeline_type.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/admin/admin_exercise.dart';
import 'package:synaptixfit/domain/models/admin/admin_page.dart';
import 'package:synaptixfit/domain/models/admin/admin_user.dart';
import 'package:synaptixfit/domain/models/admin/admin_user_stats.dart';
import 'package:synaptixfit/domain/models/admin/erasure_report.dart';

/// Datos de prueba compartidos por los tests del módulo admin.
AdminPage<T> pageOf<T>(List<T> items, {int page = 0, int totalPages = 1}) =>
    AdminPage<T>(
      items: items,
      page: page,
      size: 20,
      totalItems: items.length,
      totalPages: totalPages,
    );

const summary = AdminUserSummary(
  id: 'u1',
  email: 'ana@uni.es',
  fullName: 'Ana',
  role: UserRole.user,
  level: 3,
  levelXp: 40,
  levelThreshold: 300,
  totalXp: 640,
  streak: 2,
  shadowbanned: false,
  deleted: false,
);

const account = AdminUserAccount(
  id: 'u1',
  email: 'ana@uni.es',
  fullName: 'Ana',
  role: UserRole.user,
  level: 3,
  levelXp: 40,
  levelThreshold: 300,
  totalXp: 640,
  streak: 2,
  privacy: Visibility.private,
  shadowbanned: false,
  hasPassword: true,
  googleLinked: false,
  deleted: false,
);

const detail = AdminUserDetail(account: account);

const stats = AdminUserStats(
  trainingSessions: 4,
  trainingMinutes: 180,
  caloriesBurned: 1200,
  routines: 2,
  activeRoutines: 1,
  challenges: 3,
  completedChallenges: 1,
  badges: 2,
  subjects: 5,
  notes: 7,
  files: 1,
  completedStudyBlocks: 9,
  studyMinutes: 400,
  focusSessions: 6,
  focusMinutes: 150,
  completedDeadlines: 2,
  pendingDeadlines: 1,
  posts: 0,
  comments: 1,
  friends: 3,
  academicAdherencePercent: 80,
  adherenceWeeks: 4,
);

final timelineEntry = AdminTimelineEntry(
  occurredAt: DateTime(2026, 10, 1, 10),
  type: AdminTimelineType.trainingSession,
  title: 'Pierna',
);

const erasure = ErasureReport(
  userId: 'u1',
  mode: AdminErasureMode.deleted,
  deletedRecords: 42,
  storedFiles: 3,
  failedFileDeletions: 0,
);

const exercise = AdminExercise(
  id: 'e1',
  name: 'Sentadilla',
  difficulty: AdminExerciseDifficulty.intermediate,
  modality: AdminExerciseModality.strength,
  circuit: false,
  active: true,
  met: 5,
  instructions: ['Baja', 'Sube'],
  bodyParts: [AdminCatalogItem(id: 1, name: 'Piernas')],
  targetMuscles: [AdminCatalogItem(id: 2, name: 'Cuádriceps')],
);

const options = AdminExerciseOptions(
  bodyParts: [AdminCatalogItem(id: 1, name: 'Piernas')],
  muscles: [AdminCatalogItem(id: 2, name: 'Cuádriceps')],
  equipment: [AdminCatalogItem(id: 3, name: 'Barra')],
);
