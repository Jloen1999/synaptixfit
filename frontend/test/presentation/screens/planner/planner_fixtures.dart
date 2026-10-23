import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/models/planner/block_draft.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/domain/models/planner/deadline.dart';
import 'package:synaptixfit/domain/models/planner/focus.dart';
import 'package:synaptixfit/domain/models/planner/planner_ai.dart';
import 'package:synaptixfit/domain/models/planner/weekly_planning.dart';

/// Reloj fijo de los tests: miércoles 15/10/2025 10:00 (semana del lunes 13).
final testNow = DateTime(2025, 10, 15, 10);
final testMonday = DateTime(2025, 10, 13);

const testAccount = Account(
  id: 'u1',
  email: 'ana@uni.es',
  fullName: 'Ana',
  level: 3,
  levelXp: 40,
  levelThreshold: 300,
  streak: 2,
  privacy: Visibility.private,
  role: UserRole.user,
  hasPassword: true,
  googleLinked: false,
);

CalendarBlock block({
  String id = 'b1',
  DateTime? start,
  int minutes = 60,
  BlockType type = BlockType.study,
  bool fixed = false,
  bool completed = false,
}) {
  final s = start ?? DateTime(2025, 10, 16, 9);
  return CalendarBlock(
    id: id,
    type: type,
    start: s,
    end: s.add(Duration(minutes: minutes)),
    fixed: fixed,
    completed: completed,
  );
}

Deadline deadline({String id = 'd1', bool completed = false}) => Deadline(
  id: id,
  title: 'Práctica $id',
  type: DeadlineType.assignment,
  dueAt: DateTime(2025, 10, 20, 23, 59),
  difficulty: PlannerPriority.medium,
  completed: completed,
);

final testBalance = WeekBalance(
  weekStart: testMonday,
  plannedStudyHours: 10,
  actualStudyHours: 4,
  plannedSportHours: 3,
  actualSportHours: 1,
  state: BalanceState.studyHeavy,
);

/// Registra los valores por defecto que mocktail necesita para `any()`.
void registerPlannerFallbacks() {
  registerFallbackValue(DateTime(2000));
  registerFallbackValue(
    BlockDraft(
      type: BlockType.study,
      start: DateTime(2000),
      end: DateTime(2000),
    ),
  );
  registerFallbackValue(
    RoutineDistribution(
      routineId: 'r',
      weekdays: const {1},
      startDate: DateTime(2000),
      preferredStartMinutes: 0,
      durationMinutes: 60,
    ),
  );
  registerFallbackValue(
    DeadlineDraft(
      title: 't',
      type: DeadlineType.other,
      dueAt: DateTime(2000),
      difficulty: PlannerPriority.low,
    ),
  );
  registerFallbackValue(
    const ScheduleFile(name: 'f', bytes: [], mimeType: 'application/pdf'),
  );
  registerFallbackValue(
    const FocusSessionRecord(phase: FocusPhase.focus, durationMinutes: 1),
  );
}
