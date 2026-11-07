package com.synaptixfit.application.service.dashboard;

import com.synaptixfit.application.port.input.badge.GetStreakUseCase;
import com.synaptixfit.application.port.input.challenge.ListMyChallengesUseCase;
import com.synaptixfit.application.port.input.dashboard.GetDashboardUseCase;
import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.insights.GetPhysicalLoadUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyActivityUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyCaloriesTodayUseCase;
import com.synaptixfit.application.port.input.insights.GetWellbeingUseCase;
import com.synaptixfit.application.port.input.training.GetPendingTrainingDayUseCase;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeQuery;
import com.synaptixfit.domain.model.challenge.TaskMention;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.dashboard.BannerContext;
import com.synaptixfit.domain.model.dashboard.Dashboard;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.ActiveChallenge;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.CalendarBlock;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.Deadline;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.TrainingTotals;
import com.synaptixfit.domain.model.dashboard.SmartBanner;
import com.synaptixfit.domain.model.dashboard.SmartBannerRules;
import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CompletedStudyBlock;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.insights.DailyCheckIn;
import com.synaptixfit.domain.model.insights.StudyActivity;
import com.synaptixfit.domain.model.insights.StudyCaloriesSummary;
import com.synaptixfit.domain.model.insights.TimeZones;
import com.synaptixfit.domain.model.insights.WellbeingSnapshot;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.dashboard.DashboardReadPort;
import com.synaptixfit.domain.port.output.insights.InsightsSourcePort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Compone el resumen del inicio (antes {@code dashboard_provider}, {@code timeline_provider},
 * {@code smart_banner_provider} y varios providers de bienestar). Los retos destacados salen de
 * {@link ListMyChallengesUseCase} para que su progreso sea siempre el de {@code Challenge.progress()},
 * y los minutos de estudio de la semana de {@link GetStudyActivityUseCase}, la misma definición que
 * usan la carga cognitiva y los minutos de hoy. El enfoque de uso decide qué ámbitos entran: con
 * solo estudios no hay próximo entreno ni bloques de deporte, y con solo deporte no hay entregas
 * ni bloques académicos; el banner y los retos destacados también se limitan a ese ámbito.
 */
public class DashboardService implements GetDashboardUseCase {

    static final int TOP_CHALLENGES = 3;
    /** Retos en curso que se leen para relacionar tareas y eventos de hoy: de sobra para un uso normal. */
    static final int MAX_CHALLENGES = 50;
    static final int STREAK_LOOKBACK_DAYS = 30;
    static final int FATIGUE_WINDOW_DAYS = 3;
    static final int UPCOMING_DAYS = 7;
    /**
     * Eventos que no cuentan en el plan de la semana («Tu semana»): descanso, comida y sueño, según la definición
     * única de {@link ActivityType#countsInWeekPlan()} (lo personal sí cuenta, aunque no dé XP).
     */
    static final Set<String> NON_PLAN_TYPES = Set.copyOf(ActivityType.codesWhere(t -> !t.countsInWeekPlan()));
    /** Bloques que no se muestran como evento (la entrega/examen ya aparece por sí mismo). */
    static final Set<String> DEADLINE_BLOCK_TYPES = Set.of(ActivityType.EXAM.code(), ActivityType.DELIVERY.code());

    private final UserRepositoryPort users;
    private final DashboardReadPort reads;
    private final InsightsSourcePort insightSources;
    private final GetCognitiveStateUseCase cognitiveStates;
    private final GetCrossRegulationUseCase crossRegulation;
    private final GetStudyCaloriesTodayUseCase studyCalories;
    private final GetStudyActivityUseCase studyActivity;
    private final GetPhysicalLoadUseCase physicalLoad;
    private final GetWellbeingUseCase wellbeing;
    private final ListMyChallengesUseCase challenges;
    /** Próximo entrenamiento con la misma regla que la pestaña de Rutinas ({@code RoutineSchedule}). */
    private final GetPendingTrainingDayUseCase pendingDays;
    /** Racha efectiva al leer (null: se usa la guardada en el usuario). */
    private final GetStreakUseCase streaks;
    private final Clock clock;
    private final ZoneId defaultZone;

    public DashboardService(UserRepositoryPort users, DashboardReadPort reads, InsightsSourcePort insightSources,
                            GetCognitiveStateUseCase cognitiveStates, GetCrossRegulationUseCase crossRegulation,
                            GetStudyCaloriesTodayUseCase studyCalories, GetStudyActivityUseCase studyActivity,
                            GetPhysicalLoadUseCase physicalLoad,
                            GetWellbeingUseCase wellbeing, ListMyChallengesUseCase challenges,
                            GetPendingTrainingDayUseCase pendingDays, Clock clock, ZoneId defaultZone) {
        this(users, reads, insightSources, cognitiveStates, crossRegulation, studyCalories, studyActivity, physicalLoad,
                wellbeing, challenges, pendingDays, null, clock, defaultZone);
    }

    public DashboardService(UserRepositoryPort users, DashboardReadPort reads, InsightsSourcePort insightSources,
                            GetCognitiveStateUseCase cognitiveStates, GetCrossRegulationUseCase crossRegulation,
                            GetStudyCaloriesTodayUseCase studyCalories, GetStudyActivityUseCase studyActivity,
                            GetPhysicalLoadUseCase physicalLoad,
                            GetWellbeingUseCase wellbeing, ListMyChallengesUseCase challenges,
                            GetPendingTrainingDayUseCase pendingDays, GetStreakUseCase streaks, Clock clock,
                            ZoneId defaultZone) {
        this.pendingDays = pendingDays;
        this.streaks = streaks;
        this.users = users;
        this.reads = reads;
        this.insightSources = insightSources;
        this.cognitiveStates = cognitiveStates;
        this.crossRegulation = crossRegulation;
        this.studyCalories = studyCalories;
        this.studyActivity = studyActivity;
        this.physicalLoad = physicalLoad;
        this.wellbeing = wellbeing;
        this.challenges = challenges;
        this.clock = clock;
        this.defaultZone = defaultZone;
    }

    /** Ventana de entregas vencidas que se avisan en Inicio. */
    static final int OVERDUE_DAYS = 14;

    @Override
    public Dashboard getDashboard(UUID userId, String timeZone) {
        ZoneId zone = TimeZones.resolve(timeZone, defaultZone);
        User user = users.findById(userId).filter(User::isActive).orElseThrow(() -> new UserNotFoundException(userId));
        UsageFocus focus = user.effectiveFocus();
        String tz = zone.getId();
        Instant now = clock.instant();
        LocalDate today = LocalDate.ofInstant(now, zone);
        LocalDate weekStart = TimeZones.weekStart(today);
        Instant todayStart = TimeZones.startOfDay(today, zone);
        Instant tomorrowStart = TimeZones.startOfDay(today.plusDays(1), zone);
        Instant weekStartInstant = TimeZones.startOfDay(weekStart, zone);
        Instant weekEndInstant = TimeZones.startOfDay(weekStart.plusDays(7), zone);

        CognitiveState cognitive = cognitiveStates.getCognitiveState(userId, tz);
        CrossRegulationView regulation = crossRegulation.getCrossRegulation(userId, tz);
        StudyCaloriesSummary studyToday = studyCalories.getStudyCaloriesToday(userId, tz);
        WellbeingSnapshot wellbeingNow = wellbeing.getWellbeing(userId, tz);
        double loadToday = physicalLoad.getPhysicalLoad(userId, tz).todayLoad();

        TrainingTotals trainingToday = reads.trainingTotals(userId, todayStart, tomorrowStart);
        TrainingTotals trainingWeek = reads.trainingTotals(userId, weekStartInstant, weekEndInstant);
        List<CalendarBlock> weekBlocks = reads.calendarBlocks(userId, weekStartInstant, weekEndInstant);
        List<Deadline> deadlines = focus.includesAcademic()
                ? reads.deadlines(userId, todayStart, now.plus(Duration.ofDays(UPCOMING_DAYS)))
                : List.of();

        // Eventos que se quedaron sin hacer ayer u hoy; qué cuenta lo decide el dominio.
        Instant yesterdayStart = TimeZones.startOfDay(today.minusDays(1), zone);
        List<CalendarBlock> missed = SmartBannerRules.missedForBanner(
                reads.calendarBlocks(userId, yesterdayStart, tomorrowStart), focus, now);
        int missedBlocks = missed.size();
        int overdueDeadlines = focus.includesAcademic()
                ? (int) reads.deadlines(userId, now.minus(Duration.ofDays(OVERDUE_DAYS)), now).stream()
                        .filter(d -> ItemTimeStatus.ofDeadline(d.dueAt(), d.completed(), now) == ItemTimeStatus.MISSED)
                        .count()
                : 0;
        List<CalendarBlock> todayBlocks = weekBlocks.stream()
                .filter(b -> !b.start().isBefore(todayStart) && b.start().isBefore(tomorrowStart))
                .filter(b -> ActivityType.visibleCodeFor(b.activityType(), focus))
                .toList();
        int studyPlanned = minutes(todayBlocks.stream().filter(b -> CompletedStudyBlock.isCognitive(b.activityType())).toList());
        // Misma lista que la carga cognitiva y los minutos de hoy (bloques + práctica sin bloque):
        // si no, un Pomodoro sumaría hoy y no esta semana.
        int studyWeekCompleted = StudyActivity.minutes(
                studyActivity.getStudyActivity(userId, weekStartInstant, weekEndInstant));

        List<Challenge> active = activeChallenges(userId, focus);
        Integer planned = reads.plannedWeeklySessions(userId, weekStart).orElse(null);
        // La racha guardada solo se recalcula al evaluar insignias: se lee la de hoy para no mostrar
        // una racha que ya se rompió.
        int streak = streaks == null ? user.streak() : streaks.getStreak(userId, tz).currentDays();
        Dashboard.Greeting greeting = new Dashboard.Greeting(user.fullName(), user.avatarUrl(), user.level(),
                user.levelXp(), user.levelThreshold(), streak, user.hasBirthdayOn(today));
        Dashboard.TodayKpis todayKpis = new Dashboard.TodayKpis(today, trainingToday.calories(),
                studyToday.totalCalories(), trainingToday.sessions(), trainingToday.minutes(),
                studyToday.studyMinutes(), studyPlanned, loadToday);
        Dashboard.WeekKpis weekKpis = new Dashboard.WeekKpis(weekStart, trainingWeek.sessions(), planned,
                planned == null ? null : Math.max(0, planned - trainingWeek.sessions()), trainingWeek.minutes(),
                trainingWeek.calories(), studyWeekCompleted);

        SmartBanner banner = SmartBannerRules.choose(new BannerContext(
                regulation.zone(), regulation.acwr(), regulation.state().maxStudyMinutes(),
                (int) deadlines.stream().filter(d -> !d.completed() && !d.dueAt().isBefore(now)).count(),
                deadlines.stream().filter(d -> !d.completed() && !d.dueAt().isBefore(now)).findFirst()
                        .map(d -> (int) ChronoUnit.DAYS.between(today, LocalDate.ofInstant(d.dueAt(), zone)))
                        .orElse(null),
                recentFatigue(userId, today),
                wellbeingNow.adherence() == null ? null : wellbeingNow.adherence().score(),
                wellbeingNow.energy() == null ? null : wellbeingNow.energy().score(),
                wellbeingNow.checkInDone(),
                wellbeingNow.weeklyLoad() == null ? null : wellbeingNow.weeklyLoad().stressLevel(),
                cognitive.attentionCapacity(), cognitive.cognitiveLoad(), streak,
                studyStreak(userId, today, zone),
                reads.lastTrainingSession(userId)
                        .map(last -> (int) ChronoUnit.DAYS.between(LocalDate.ofInstant(last, zone), today))
                        .orElse(null),
                focus, overdueDeadlines, missedBlocks));
        if (banner.type() == SmartBanner.Type.MISSED_BLOCKS) {
            banner = SmartBannerRules.describeLatestMissed(banner, missed, today, zone);
        }

        return new Dashboard(greeting, todayKpis, weekKpis, cognitive, regulation, wellbeingNow,
                focus.includesFitness()
                        ? pendingDays.pendingDay(userId).orElse(null)
                        : null,
                active.stream().limit(TOP_CHALLENGES).map(ActiveChallenge::of).toList(),
                planWeek(weekStart, weekBlocks.stream()
                        .filter(b -> ActivityType.visibleCodeFor(b.activityType(), focus)).toList(), zone, now),
                withTasks(todayEvents(todayBlocks, deadlines, todayStart, tomorrowStart, now), todayBlocks,
                        active.stream().filter(c -> c.status(now) == ChallengeStatus.ACTIVE).toList()),
                banner);
    }

    /**
     * Retos activos (no completados ni vencidos) del ámbito que usa la persona, los que terminan antes primero. Los
     * {@link #TOP_CHALLENGES} primeros se destacan; todos sirven para decir qué tarea adelanta cada evento de hoy.
     */
    private List<Challenge> activeChallenges(UUID userId, UsageFocus focus) {
        return challenges.listMyChallenges(userId,
                        new ChallengeQuery(ChallengeStatus.ACTIVE, ChallengeType.onlyFor(focus), null, null),
                        new PageRequest(0, MAX_CHALLENGES))
                .items();
    }

    /**
     * Cada evento de hoy con las tareas de reto que hace avanzar (ADR 0035): un evento, la tarea a la que está
     * asignado; una entrega, las tareas (o el reto) que se completan con ella. Así una tarea no sale dos veces y la
     * fila lo sigue diciendo después de marcarla. Solo cuentan los retos en curso.
     */
    static List<Dashboard.TodayEvent> withTasks(List<Dashboard.TodayEvent> events, List<CalendarBlock> blocks,
                                                List<Challenge> active) {
        if (active.isEmpty()) {
            return events;
        }
        Map<UUID, TaskMention> byMilestone = TaskMention.byMilestone(active);
        Map<UUID, List<TaskMention>> byDeadline = TaskMention.byDeadline(active);
        Map<UUID, List<TaskMention>> byRoutineDay = TaskMention.byRoutineDay(active);
        Map<UUID, UUID> milestoneOfBlock = new HashMap<>();
        Map<UUID, UUID> routineDayOfBlock = new HashMap<>();
        blocks.stream().filter(b -> b.milestoneId() != null).forEach(b -> milestoneOfBlock.put(b.id(), b.milestoneId()));
        blocks.stream().filter(b -> b.routineDayId() != null)
                .forEach(b -> routineDayOfBlock.put(b.id(), b.routineDayId()));
        return events.stream().map(e -> {
            if (e.kind() == Dashboard.TodayEvent.Kind.DEADLINE) {
                return e.withTasks(byDeadline.getOrDefault(e.id(), List.of()));
            }
            // La tarea asignada al evento y las que avanzan al entrenar su día de rutina, sin repetir.
            List<TaskMention> tasks = new ArrayList<>();
            TaskMention assigned = byMilestone.get(milestoneOfBlock.get(e.id()));
            if (assigned != null) {
                tasks.add(assigned);
            }
            byRoutineDay.getOrDefault(routineDayOfBlock.get(e.id()), List.of()).stream()
                    .filter(t -> !tasks.contains(t)).forEach(tasks::add);
            return tasks.isEmpty() ? e : e.withTasks(tasks);
        }).toList();
    }

    private static int minutes(List<CalendarBlock> blocks) {
        return (int) blocks.stream().mapToLong(b -> Math.max(0, Duration.between(b.start(), b.end()).toMinutes())).sum();
    }

    static List<Dashboard.PlanDay> planWeek(LocalDate weekStart, List<CalendarBlock> blocks, ZoneId zone) {
        return planWeek(weekStart, blocks, zone, Instant.MIN);
    }

    static List<Dashboard.PlanDay> planWeek(LocalDate weekStart, List<CalendarBlock> blocks, ZoneId zone,
                                            Instant now) {
        List<Dashboard.PlanDay> days = new ArrayList<>(7);
        for (int i = 0; i < 7; i++) {
            LocalDate day = weekStart.plusDays(i);
            List<CalendarBlock> ofDay = blocks.stream()
                    .filter(b -> !NON_PLAN_TYPES.contains(b.activityType()))
                    .filter(b -> LocalDate.ofInstant(b.start(), zone).equals(day))
                    .toList();
            int missed = (int) ofDay.stream().filter(b -> status(b, now) == ItemTimeStatus.MISSED).count();
            days.add(new Dashboard.PlanDay(day, ofDay.size(),
                    (int) ofDay.stream().filter(CalendarBlock::completed).count(), missed));
        }
        return days;
    }

    static ItemTimeStatus status(CalendarBlock b, Instant now) {
        return ItemTimeStatus.ofBlock(ActivityType.fromCode(b.activityType()), b.start(), b.end(), b.completed(), now);
    }

    static List<Dashboard.TodayEvent> todayEvents(List<CalendarBlock> todayBlocks, List<Deadline> deadlines,
                                                  Instant todayStart, Instant tomorrowStart) {
        return todayEvents(todayBlocks, deadlines, todayStart, tomorrowStart, todayStart);
    }

    static List<Dashboard.TodayEvent> todayEvents(List<CalendarBlock> todayBlocks, List<Deadline> deadlines,
                                                  Instant todayStart, Instant tomorrowStart, Instant now) {
        List<Dashboard.TodayEvent> events = new ArrayList<>();
        for (CalendarBlock b : todayBlocks) {
            if (DEADLINE_BLOCK_TYPES.contains(b.activityType())) {
                continue;
            }
            String title = b.subjectName() != null ? b.subjectName() : b.topics();
            events.add(new Dashboard.TodayEvent(Dashboard.TodayEvent.Kind.BLOCK, b.id(), title, b.activityType(),
                    b.start(), b.end(), b.completed(), b.subjectName(), status(b, now), b.routineId(),
                    b.routineDayId()));
        }
        for (Deadline d : deadlines) {
            if (!d.dueAt().isBefore(todayStart) && d.dueAt().isBefore(tomorrowStart)) {
                events.add(new Dashboard.TodayEvent(Dashboard.TodayEvent.Kind.DEADLINE, d.id(), d.title(), d.type(),
                        d.dueAt(), null, d.completed(), d.subjectName(),
                        ItemTimeStatus.ofDeadline(d.dueAt(), d.completed(), now)));
            }
        }
        events.sort(Comparator.comparing(Dashboard.TodayEvent::start));
        return events;
    }

    /** Fatiga media (0-100) de los check-ins de los últimos 3 días; null si no hay ninguno. */
    private Integer recentFatigue(UUID userId, LocalDate today) {
        List<DailyCheckIn> recent = insightSources.checkIns(userId, today.minusDays(FATIGUE_WINDOW_DAYS - 1L), today);
        if (recent.isEmpty()) {
            return null;
        }
        return (int) Math.round(recent.stream().mapToInt(DailyCheckIn::fatigueScore).average().orElse(0));
    }

    /**
     * Días consecutivos con algún bloque de estudio o repaso completado, terminando hoy (o ayer si
     * hoy aún no hay ninguno).
     */
    private int studyStreak(UUID userId, LocalDate today, ZoneId zone) {
        Set<LocalDate> days = insightSources.completedStudyBlocks(userId,
                        TimeZones.startOfDay(today.minusDays(STREAK_LOOKBACK_DAYS), zone),
                        TimeZones.startOfDay(today.plusDays(1), zone)).stream()
                .filter(b -> ActivityType.countsAsStudyCode(b.activityType()))
                .map(b -> LocalDate.ofInstant(b.start(), zone))
                .collect(Collectors.toSet());
        return consecutiveDays(days, today);
    }

    static int consecutiveDays(Set<LocalDate> days, LocalDate today) {
        LocalDate cursor = days.contains(today) ? today : today.minusDays(1);
        int count = 0;
        while (days.contains(cursor)) {
            count++;
            cursor = cursor.minusDays(1);
        }
        return count;
    }
}
