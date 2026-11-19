import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/home_acwr_zone.dart';
import 'package:synaptixfit/domain/enums/home_banner_type.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/domain/models/home/today_next.dart';

/// El botón de la fila de «Tu día» y qué se nombra (ADR 0059): el evento y si
/// el entreno es hoy los dice el servidor; aquí solo se elige el botón.
void main() {
  HomeTodayEvent event(
    HomeEventType type, {
    ItemTimeStatus status = ItemTimeStatus.upcoming,
    HomeEventKind kind = HomeEventKind.block,
    bool completed = false,
  }) => HomeTodayEvent(
    id: 'e',
    kind: kind,
    type: type,
    title: 'Evento',
    completed: completed,
    status: status,
  );

  test('estudio y repaso se concentran; una clase o un partido por empezar '
      'no llevan botón', () {
    expect(TodayAction.forEvent(event(HomeEventType.study)), TodayAction.focus);
    expect(
      TodayAction.forEvent(event(HomeEventType.review)),
      TodayAction.focus,
    );
    expect(TodayAction.forEvent(event(HomeEventType.classSession)), isNull);
    expect(TodayAction.forEvent(event(HomeEventType.sport)), isNull);
    expect(TodayAction.forEvent(event(HomeEventType.personal)), isNull);
  });

  test('lo personal o un partido en curso, y lo que quedó sin hacer, se '
      'marcan', () {
    expect(
      TodayAction.forEvent(
        event(HomeEventType.personal, status: ItemTimeStatus.inProgress),
      ),
      TodayAction.markDone,
    );
    expect(
      TodayAction.forEvent(
        event(HomeEventType.sport, status: ItemTimeStatus.inProgress),
      ),
      TodayAction.markDone,
    );
    expect(
      TodayAction.forEvent(
        event(HomeEventType.study, status: ItemTimeStatus.missed),
      ),
      TodayAction.markDone,
    );
    // Una clase pasada no se marca.
    expect(
      TodayAction.forEvent(
        event(HomeEventType.classSession, status: ItemTimeStatus.missed),
      ),
      isNull,
    );
    // Una entrega se puede adelantar; ya hecha, sin botón.
    final delivery = event(
      HomeEventType.delivery,
      kind: HomeEventKind.deadline,
    );
    expect(TodayAction.forEvent(delivery), TodayAction.markDone);
    expect(TodayAction.forEvent(delivery.copyWith(completed: true)), isNull);
  });

  test('la fila nombra el evento del servidor y el entreno solo si es hoy', () {
    const training = HomeNextTrainingDay(
      routineId: 'r',
      routineName: 'Fuerza',
      dayId: 'd',
      weekNumber: 1,
      dayNumber: 1,
      inProgress: false,
    );
    final base = HomeDashboard(
      greeting: const HomeGreeting(
        fullName: 'Ana',
        level: 1,
        levelXp: 0,
        levelThreshold: 100,
        streak: 0,
      ),
      today: const HomeTodayKpis(
        trainingCalories: 0,
        studyCalories: 0,
        totalCalories: 0,
        sessions: 0,
        trainingMinutes: 0,
        studyMinutesCompleted: 0,
        studyMinutesPlanned: 0,
      ),
      week: const HomeWeekKpis(
        sessions: 0,
        trainingMinutes: 0,
        trainingCalories: 0,
        studyMinutesCompleted: 0,
      ),
      cognitive: const HomeCognitiveState(
        cognitiveLoad: 0,
        attentionCapacity: 1,
        lastBlockMinutes: 0,
      ),
      crossRegulation: const HomeCrossRegulation(
        zone: HomeAcwrZone.optimal,
        maxStudyMinutes: 0,
        focusMinutes: 50,
        focusBreakMinutes: 10,
      ),
      wellbeing: const HomeWellbeing(checkInDone: false),
      banner: const HomeSmartBanner(type: HomeBannerType.balance),
      todayEvents: [event(HomeEventType.classSession)],
      todaySummary: const HomeTodaySummary(spotlightEventId: 'e'),
      nextTrainingDay: training,
    );

    expect(base.spotlight?.id, 'e');
    expect(base.trainingToday, isNull);
    expect(
      base
          .copyWith(nextTrainingDay: training.copyWith(dueToday: true))
          .trainingToday,
      isNotNull,
    );
    expect(
      base.copyWith(todaySummary: const HomeTodaySummary()).spotlight,
      isNull,
    );
  });

  test('«y N más» cuenta lo que queda sin nombrar; los días de rutina, solo '
      'si no sale el entreno', () {
    HomeTodayEvent e(
      String id,
      HomeEventType type, {
      ItemTimeStatus status = ItemTimeStatus.upcoming,
      bool routine = false,
    }) => HomeTodayEvent(
      id: id,
      kind: HomeEventKind.block,
      type: type,
      title: id,
      completed: status == ItemTimeStatus.done,
      status: status,
      routineId: routine ? 'r' : null,
      routineDayId: routine ? 'd' : null,
    );
    final day = HomeDashboard(
      greeting: const HomeGreeting(
        fullName: 'Ana',
        level: 1,
        levelXp: 0,
        levelThreshold: 100,
        streak: 0,
      ),
      today: const HomeTodayKpis(
        trainingCalories: 0,
        studyCalories: 0,
        totalCalories: 0,
        sessions: 0,
        trainingMinutes: 0,
        studyMinutesCompleted: 0,
        studyMinutesPlanned: 0,
      ),
      week: const HomeWeekKpis(
        sessions: 0,
        trainingMinutes: 0,
        trainingCalories: 0,
        studyMinutesCompleted: 0,
      ),
      cognitive: const HomeCognitiveState(
        cognitiveLoad: 0,
        attentionCapacity: 1,
        lastBlockMinutes: 0,
      ),
      crossRegulation: const HomeCrossRegulation(
        zone: HomeAcwrZone.optimal,
        maxStudyMinutes: 0,
        focusMinutes: 50,
        focusBreakMinutes: 10,
      ),
      wellbeing: const HomeWellbeing(checkInDone: false),
      banner: const HomeSmartBanner(type: HomeBannerType.balance),
      todayEvents: [
        e('shown', HomeEventType.study),
        e('done', HomeEventType.study, status: ItemTimeStatus.done),
        e('class', HomeEventType.classSession),
        e('gym', HomeEventType.sport, routine: true),
        e('review', HomeEventType.review),
      ],
    );

    expect(day.othersPending(shownIds: {'shown'}, trainingShown: true), 1);
    expect(day.othersPending(shownIds: {'shown'}, trainingShown: false), 2);
    expect(day.todayEvents[3].isRoutineDay, isTrue);
    expect(day.todayEvents[0].isRoutineDay, isFalse);
  });
}
