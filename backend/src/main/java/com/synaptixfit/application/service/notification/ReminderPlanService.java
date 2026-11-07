package com.synaptixfit.application.service.notification;

import com.synaptixfit.application.port.input.challenge.ListMyChallengesUseCase;
import com.synaptixfit.application.port.input.badge.GetStreakUseCase;
import com.synaptixfit.application.port.input.notification.GetReminderPlanUseCase;
import com.synaptixfit.application.port.input.training.GetPendingTrainingDayUseCase;
import com.synaptixfit.application.port.input.training.GetTodayCheckInUseCase;
import com.synaptixfit.application.port.input.training.ListOpenSessionsUseCase;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeQuery;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.DatedTask;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.model.notification.NotificationPreferences;
import com.synaptixfit.domain.model.notification.ReminderPlan;
import com.synaptixfit.domain.model.notification.ReminderOptions;
import com.synaptixfit.domain.model.notification.ReminderPlanner;
import com.synaptixfit.domain.model.notification.WellbeingReminders;
import com.synaptixfit.domain.model.badge.StreakStatus;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.training.ProgressStatus;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.port.output.notification.ExamCalendarPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.notification.NotificationPreferencesRepositoryPort;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import com.synaptixfit.domain.port.output.user.UsageFocusPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;
import java.util.stream.Collectors;

/**
 * Implementa {@link GetReminderPlanUseCase}: reúne preferencias, enfoque de uso, repasos vencidos y
 * bloques del planificador y deja que {@link ReminderPlanner} decida. Solo lee lo que se va a avisar.
 * Los avisos de seguimiento leen el próximo día de rutina ({@link GetPendingTrainingDayUseCase}), las sesiones
 * abiertas ({@link ListOpenSessionsUseCase}) y los retos activos ({@link ListMyChallengesUseCase}). Los de bienestar
 * ({@link WellbeingReminders}: racha, registro diario y clase) leen sus opciones, la racha y el registro de hoy
 * ({@link Wellbeing}). Las tareas de reto con fecha ({@link DatedTask}) salen de los retos activos, de los eventos de la
 * ventana y del próximo día de rutina; las antelaciones y el resumen de la mañana, de {@link ReminderOptions}.
 */
public class ReminderPlanService implements GetReminderPlanUseCase {

    /** Igual que el listado de repasos vencidos: el número del aviso no pasa de aquí. */
    static final int MAX_COUNTED_REVIEWS = 100;
    /** Retos activos que se miran para «vence mañana»: de sobra para un uso normal. */
    static final int MAX_CHALLENGES = 50;

    private final NotificationPreferencesRepositoryPort preferences;
    private final UsageFocusPort focus;
    private final StudyMaterialRepositoryPort materials;
    private final CalendarBlockRepositoryPort blocks;
    private final DeadlineRepositoryPort deadlines;
    private final SubjectDirectoryPort subjects;
    private final ReminderPlanner planner;
    private final ExamCalendarPort exams;
    private final Clock clock;
    private final ZoneId zone;
    private final GetPendingTrainingDayUseCase pendingDay;
    private final ListOpenSessionsUseCase openSessions;
    private final ListMyChallengesUseCase challenges;
    private final Wellbeing wellbeing;

    /** Fuentes de los avisos de bienestar; nulas: no se avisan. */
    public record Wellbeing(ReminderOptionsRepositoryPort options, GetStreakUseCase streak,
                            GetTodayCheckInUseCase checkIn) {
    }

    public ReminderPlanService(NotificationPreferencesRepositoryPort preferences, UsageFocusPort focus,
                               StudyMaterialRepositoryPort materials, CalendarBlockRepositoryPort blocks,
                               DeadlineRepositoryPort deadlines, SubjectDirectoryPort subjects,
                               ReminderPlanner planner, ExamCalendarPort exams, Clock clock, ZoneId zone) {
        this(preferences, focus, materials, blocks, deadlines, subjects, planner, exams, clock, zone, null, null,
                null);
    }

    /** Con las fuentes de los avisos de seguimiento (nulas: no se avisan). */
    public ReminderPlanService(NotificationPreferencesRepositoryPort preferences, UsageFocusPort focus,
                               StudyMaterialRepositoryPort materials, CalendarBlockRepositoryPort blocks,
                               DeadlineRepositoryPort deadlines, SubjectDirectoryPort subjects,
                               ReminderPlanner planner, ExamCalendarPort exams, Clock clock, ZoneId zone,
                               GetPendingTrainingDayUseCase pendingDay, ListOpenSessionsUseCase openSessions,
                               ListMyChallengesUseCase challenges) {
        this(preferences, focus, materials, blocks, deadlines, subjects, planner, exams, clock, zone, pendingDay,
                openSessions, challenges, null);
    }

    /** Con las fuentes de los avisos de bienestar (nulas: no se avisan). */
    public ReminderPlanService(NotificationPreferencesRepositoryPort preferences, UsageFocusPort focus,
                               StudyMaterialRepositoryPort materials, CalendarBlockRepositoryPort blocks,
                               DeadlineRepositoryPort deadlines, SubjectDirectoryPort subjects,
                               ReminderPlanner planner, ExamCalendarPort exams, Clock clock, ZoneId zone,
                               GetPendingTrainingDayUseCase pendingDay, ListOpenSessionsUseCase openSessions,
                               ListMyChallengesUseCase challenges, Wellbeing wellbeing) {
        this.wellbeing = wellbeing;
        this.preferences = preferences;
        this.focus = focus;
        this.materials = materials;
        this.blocks = blocks;
        this.deadlines = deadlines;
        this.subjects = subjects;
        this.planner = planner;
        this.exams = exams;
        this.clock = clock;
        this.zone = zone;
        this.pendingDay = pendingDay;
        this.openSessions = openSessions;
        this.challenges = challenges;
    }

    @Override
    public ReminderPlan getReminderPlan(UUID userId, int days) {
        Instant now = clock.instant();
        Instant end = ReminderPlanner.horizonEnd(now, days);
        NotificationPreferences stored = preferences.findByUserId(userId)
                .orElseGet(() -> NotificationPreferences.defaults(userId, now));
        // Modo exámenes automático (como en las notificaciones): solo avisos de estudio esa semana.
        boolean examSeason = exams.hasExamBetween(userId, now,
                now.plus(Duration.ofDays(NotificationPreferences.EXAM_SEASON_DAYS)));
        NotificationPreferences prefs = examSeason ? stored.duringExamSeason() : stored;
        UsageFocus usageFocus = focus.focusOf(userId);

        int dueReviews = ReminderPlanner.wantsReviews(prefs, usageFocus)
                ? materials.findDue(userId, now, MAX_COUNTED_REVIEWS).size() : 0;
        // Los bloques de la ventana sirven a los avisos de bloque y a los de clase: se leen una sola vez.
        List<List<CalendarBlock>> window = new ArrayList<>(1);
        Supplier<List<CalendarBlock>> blocksInWindow = () -> {
            if (window.isEmpty()) {
                window.add(blocks.findOverlapping(userId, now, end, null));
            }
            return window.get(0);
        };
        List<ReminderPlanner.Block> upcoming = ReminderPlanner.wantsBlocks(prefs, usageFocus)
                ? toBlocks(userId, blocksInWindow.get()) : List.of();

        ReminderOptions options = wellbeing == null ? ReminderOptions.DEFAULTS
                : wellbeing.options().find(userId).orElse(ReminderOptions.DEFAULTS);
        List<ReminderPlanner.Deadline> pending = ReminderPlanner.wantsDeadlines(prefs, usageFocus)
                ? deadlines.findAll(userId, new DeadlineRepositoryPort.Query(now,
                        ReminderPlanner.deadlineHorizon(now, days), null, true)).stream()
                        .map(d -> new ReminderPlanner.Deadline(d.id(), d.type() == DeadlineType.EXAM, d.title(),
                                d.dueAt()))
                        .toList()
                : List.of();

        if (prefs.dailyLimit() <= 0) {
            return ReminderPlan.empty();
        }
        ReminderPlanner.RoutineDay day = nextRoutineDay(userId);
        List<Challenge> active = activeChallenges(userId, usageFocus, now);
        List<CalendarBlock> events = ReminderPlanner.wantsBlocks(prefs, usageFocus) ? blocksInWindow.get() : List.of();
        List<DatedTask> tasks = DatedTask.of(active, events.stream()
                        .map(b -> new DatedTask.EventRef(b.id(), b.details().milestoneId(), b.details().routineDayId(),
                                b.start(), b.completed()))
                        .toList(),
                day == null ? null : new DatedTask.RoutineDayRef(day.dayId(),
                        day.scheduledDate().atStartOfDay(zone).toInstant()),
                now);
        return planner.plan(new ReminderPlanner.Input(dueReviews, upcoming, prefs, usageFocus, now, zone, days,
                pending, true, followUps(userId, day, active), options, tasks),
                wellbeingReminders(userId, prefs, usageFocus, options, now, end, blocksInWindow));
    }

    /** Racha en riesgo, registro diario y clase a punto de empezar, según las opciones del usuario. */
    private List<ReminderPlan.Item> wellbeingReminders(UUID userId, NotificationPreferences prefs, UsageFocus focus,
                                                       ReminderOptions options, Instant now, Instant end,
                                                       Supplier<List<CalendarBlock>> blocksInWindow) {
        if (wellbeing == null || prefs.dailyLimit() <= 0) {
            return List.of();
        }
        StreakStatus streak = options.streak() ? wellbeing.streak().getStreak(userId, zone.getId()) : null;
        boolean checkInDone = options.checkIn() && wellbeing.checkIn().today(userId).isPresent();
        List<WellbeingReminders.ClassBlock> classes = options.classes()
                ? toClasses(userId, blocksInWindow.get()) : List.of();
        return WellbeingReminders.plan(new WellbeingReminders.Input(prefs, focus, options, now, zone, end,
                streak == null ? 0 : streak.currentDays(), streak != null && streak.activeToday(), checkInDone,
                classes));
    }

    /** Clases de la ventana con su asignatura (o temas) y su aula. */
    private List<WellbeingReminders.ClassBlock> toClasses(UUID userId, List<CalendarBlock> found) {
        List<CalendarBlock> classes = found.stream().filter(b -> b.type() == ActivityType.CLASS).toList();
        Set<UUID> subjectIds = classes.stream().map(CalendarBlock::subjectId).filter(Objects::nonNull)
                .collect(Collectors.toSet());
        Map<UUID, String> names = subjectIds.isEmpty() ? Map.of() : subjects.namesOf(userId, subjectIds);
        return classes.stream().map(b -> new WellbeingReminders.ClassBlock(b.id(),
                b.subjectId() != null && names.get(b.subjectId()) != null ? names.get(b.subjectId())
                        : b.details().topics(),
                b.details().location(), b.start(), b.completed() || b.absent())).toList();
    }

    /** Próximo día de rutina sin empezar y con fecha prevista; nulo si no hay. */
    private ReminderPlanner.RoutineDay nextRoutineDay(UUID userId) {
        return pendingDay == null ? null : pendingDay.pendingDay(userId)
                .filter(p -> p.status() == ProgressStatus.PENDING && p.scheduledDate() != null)
                .map(p -> new ReminderPlanner.RoutineDay(p.day().id(), p.routine().name(), p.scheduledDate()))
                .orElse(null);
    }

    /** Retos propios en curso ahora del ámbito que usa la persona (con sus tareas y lo que las completa). */
    private List<Challenge> activeChallenges(UUID userId, UsageFocus usageFocus, Instant now) {
        return challenges == null ? List.of() : challenges.listMyChallenges(userId,
                        new ChallengeQuery(ChallengeStatus.ACTIVE, ChallengeType.onlyFor(usageFocus), null, null),
                        new PageRequest(0, MAX_CHALLENGES)).items().stream()
                .filter(c -> c.status(now) == ChallengeStatus.ACTIVE)
                .toList();
    }

    /** Próximo día de rutina, sesiones abiertas aún no abandonadas y retos activos. */
    private ReminderPlanner.FollowUps followUps(UUID userId, ReminderPlanner.RoutineDay day, List<Challenge> active) {
        List<ReminderPlanner.OpenSession> open = openSessions == null ? List.of() : openSessions.listOpen(userId)
                .stream().filter(o -> !o.stale())
                .map(o -> new ReminderPlanner.OpenSession(o.session().id(),
                        o.label() == null ? null : o.label().routineName(), o.session().startedAt()))
                .toList();
        List<ReminderPlanner.ChallengeDue> due = active.stream()
                .map(c -> new ReminderPlanner.ChallengeDue(c.id(), c.title(), c.endAt()))
                .toList();
        return new ReminderPlanner.FollowUps(day, open, due);
    }

    /** Título del aviso: los temas del bloque o, si no hay, el nombre de su asignatura. */
    private List<ReminderPlanner.Block> toBlocks(UUID userId, List<CalendarBlock> found) {
        Set<UUID> subjectIds = found.stream()
                .filter(b -> b.details().topics() == null)
                .map(CalendarBlock::subjectId).filter(Objects::nonNull).collect(Collectors.toSet());
        Map<UUID, String> names = subjectIds.isEmpty() ? Map.of() : subjects.namesOf(userId, subjectIds);
        return found.stream().map(b -> new ReminderPlanner.Block(b.id(), b.type(), b.start(),
                b.details().topics() != null ? b.details().topics()
                        : b.subjectId() == null ? null : names.get(b.subjectId()),
                b.completed())).toList();
    }
}
