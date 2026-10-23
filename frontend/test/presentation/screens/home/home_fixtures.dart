import 'package:synaptixfit/domain/enums/home_acwr_zone.dart';
import 'package:synaptixfit/domain/enums/home_banner_type.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/domain/models/home/home_due_review.dart';

/// Datos de ejemplo del inicio para los tests.
final homeDashboardFixture = HomeDashboard(
  greeting: const HomeGreeting(
    fullName: 'Ana López',
    level: 3,
    levelXp: 120,
    levelThreshold: 300,
    streak: 4,
  ),
  today: const HomeTodayKpis(
    trainingCalories: 320.4,
    studyCalories: 95.2,
    totalCalories: 1820.6,
    sessions: 1,
    trainingMinutes: 45,
    studyMinutesCompleted: 60,
    studyMinutesPlanned: 120,
  ),
  week: const HomeWeekKpis(
    sessions: 3,
    plannedSessions: 4,
    trainingMinutes: 150,
    trainingCalories: 980,
    studyMinutesCompleted: 420,
  ),
  cognitive: const HomeCognitiveState(
    cognitiveLoad: 0.42,
    attentionCapacity: 0.81,
    lastBlockMinutes: 50,
  ),
  crossRegulation: const HomeCrossRegulation(
    acwr: 1.05,
    zone: HomeAcwrZone.optimal,
    maxStudyMinutes: 240,
    focusMinutes: 52,
    focusBreakMinutes: 17,
  ),
  wellbeing: const HomeWellbeing(checkInDone: false, energyScore: null),
  nextTrainingDay: const HomeNextTrainingDay(
    routineId: 'r1',
    routineName: 'Fuerza base',
    dayId: 'd1',
    weekNumber: 1,
    dayNumber: 2,
    dayName: 'Tren superior',
    inProgress: false,
  ),
  activeChallenges: [
    HomeChallenge(
      id: 'c1',
      title: 'Estudiar 10 horas',
      academic: true,
      endsAt: DateTime(2030, 1, 10),
      progress: 40,
      currentStreak: 2,
    ),
  ],
  planWeek: [
    for (var i = 0; i < 7; i++)
      HomePlanDay(
        date: DateTime(2026, 10, 12 + i),
        planned: i < 5 ? 3 : 0,
        completed: i < 3 ? 2 : 0,
      ),
  ],
  todayEvents: [
    HomeTodayEvent(
      id: 'e1',
      kind: HomeEventKind.block,
      type: HomeEventType.study,
      title: 'Cálculo',
      start: DateTime(2026, 10, 18, 10),
      end: DateTime(2026, 10, 18, 11, 30),
      completed: false,
      subjectName: 'Matemáticas',
    ),
    HomeTodayEvent(
      id: 'e2',
      kind: HomeEventKind.deadline,
      type: HomeEventType.delivery,
      title: 'Práctica 2',
      start: DateTime(2026, 10, 18, 23, 59),
      completed: true,
    ),
  ],
  banner: const HomeSmartBanner(
    type: HomeBannerType.upcomingDeadlines,
    params: {'count': 2, 'daysUntilNext': 3},
  ),
);

const homeReviewsFixture = [HomeDueReview(id: 'm1', title: 'Tema 3: Límites')];
