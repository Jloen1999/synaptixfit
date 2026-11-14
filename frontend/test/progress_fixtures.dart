import 'package:synaptixfit/domain/enums/analytics_enums.dart';
import 'package:synaptixfit/domain/enums/analytics_period.dart';
import 'package:synaptixfit/domain/enums/badge_category.dart';
import 'package:synaptixfit/domain/enums/badge_criterion.dart';
import 'package:synaptixfit/domain/enums/badge_rarity.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/models/progress/analytics_insight.dart';
import 'package:synaptixfit/domain/models/progress/analytics_report.dart';
import 'package:synaptixfit/domain/models/progress/badge.dart';
import 'package:synaptixfit/domain/models/progress/load_correlation.dart';
import 'package:synaptixfit/domain/models/progress/progress_overview.dart';
import 'package:synaptixfit/domain/models/progress/rpe_trend.dart';
import 'package:synaptixfit/domain/models/progress/streak.dart';
import 'package:synaptixfit/domain/models/progress/training_volume.dart';
import 'package:synaptixfit/domain/models/progress/weekly_analytics.dart';

/// Datos de prueba compartidos por los tests del módulo progress.
const testAccount = Account(
  id: 'u1',
  email: 'ana@uni.es',
  fullName: 'Ana',
  level: 3,
  levelXp: 120,
  levelThreshold: 300,
  streak: 5,
  privacy: Visibility.private,
  role: UserRole.user,
  hasPassword: true,
  googleLinked: false,
);

const testStreak = Streak(
  currentDays: 5,
  bestDays: 12,
  activeToday: false,
  atRisk: true,
  nextMilestone: 7,
  daysToNextMilestone: 2,
  milestoneProgress: 5 / 7,
  reachedMilestones: [7],
);

Badge testBadge({
  String id = 'b1',
  bool earned = true,
  bool visible = true,
  BadgeCategory category = BadgeCategory.training,
  int order = 1,
}) => Badge(
  id: id,
  name: 'Primeros pasos',
  description: 'Completa tu primera sesión',
  icon: '🏅',
  category: category,
  criterion: BadgeCriterion.sessionsCompleted,
  criterionValue: 10,
  rarity: BadgeRarity.common,
  order: order,
  earned: earned,
  earnedAt: earned ? DateTime(2026, 10, 1) : null,
  visible: earned && visible,
  currentValue: earned ? 10 : 4,
  progress: earned ? 1 : 0.4,
);

final testOverview = ProgressOverview(
  account: testAccount,
  streak: testStreak,
  earnedBadges: [testBadge()],
);

final testWeekly = WeeklyAnalytics(
  period: AnalyticsPeriod.monthly,
  currentWeekStart: DateTime(2026, 10, 5),
  weeks: [
    WeekMetric(
      weekStart: DateTime(2026, 10, 5),
      sessions: 3,
      averageRpe: 7,
      totalMinutes: 150,
      totalCalories: 900,
    ),
  ],
  totalSessions: 3,
  totalMinutes: 150,
  totalCalories: 900,
  averageRpe: 7,
);

LoadCorrelation testCorrelation(CorrelationMetric metric) => LoadCorrelation(
  metric: metric,
  coefficient: -0.62,
  sampleSize: 6,
  minimumSampleSize: 4,
  sufficientData: true,
  strength: CorrelationStrength.strong,
  direction: CorrelationDirection.negative,
  points: [
    CorrelationPoint(
      weekStart: DateTime(2026, 10, 5),
      studyHours: 12,
      trainingValue: 6.5,
    ),
  ],
);

AnalyticsReport testReport({
  CorrelationMetric metric = CorrelationMetric.rpe,
}) => AnalyticsReport(
  weekly: testWeekly,
  volume: const TrainingVolume(
    points: [],
    averageMinutesPerWeek: 37.5,
    averageCaloriesPerWeek: 225,
    averageSessionsPerWeek: 0.75,
  ),
  rpeTrend: const RpeTrend(points: [], direction: TrendDirection.stable),
  correlation: testCorrelation(metric),
  insights: const [
    AnalyticsInsight(
      type: InsightType.streak,
      severity: InsightSeverity.positive,
      variant: 'BUILDING',
      params: {'days': 3, 'weeks': 0},
    ),
  ],
);
