package com.synaptixfit.domain.model.notification;

import com.synaptixfit.domain.model.challenge.DatedTask;
import com.synaptixfit.domain.model.challenge.TaskMention;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.user.BirthDate;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Decide qué recordatorios locales programa el móvil (ADR 0013): repasos vencidos y bloques del
 * planificador a punto de empezar, filtrados con las preferencias de notificación y el enfoque de
 * uso. Lógica pura; la usa {@code ReminderPlanService}.
 *
 * <p>Reglas:
 * <ul>
 *   <li>Repasos: a las 19:00 de los tres próximos días (hoy solo si aún no han pasado), si hay
 *       vencidos. Más de un día para que siga avisando aunque no se abra la app.</li>
 *   <li>Eventos de deporte, estudio, repaso y personales: los minutos elegidos antes de empezar
 *       ({@link ReminderOptions#eventLeadMinutes()}, 15 por defecto). Se descartan los completados, los ya
 *       empezados y el resto de tipos (las clases van en {@link WellbeingReminders}; exámenes y entregas, por su
 *       entrega). Lo personal no tiene categoría propia: se avisa si la persona admite alguna
 *       ({@link #admitsAny}), porque son sus citas y no deben callarse en época de exámenes.</li>
 *   <li>«Tu semana»: el domingo a las {@link #WEEKLY_TIME}, para mirar cómo ha ido y planificar la siguiente
 *       (categoría académica o de hitos, la que esté activa).</li>
 *   <li>Entregas y exámenes pendientes: a las 18:00 de los días antes elegidos
 *       ({@link ReminderOptions#deadlineDaysBefore()}; por defecto 3 y 1: con tres días aún hay margen para
 *       organizarse y el día antes sirve de último aviso). Categoría académica.</li>
 *   <li>Tareas de reto con fecha ({@link DatedTask}): nunca dos avisos por lo mismo. Si su entrega o su evento ya
 *       tiene aviso, ese aviso menciona la tarea; si no, la tarea tiene el suyo
 *       ({@link ReminderKind#CHALLENGE_TASK}) la tarde anterior a las {@link #DEADLINE_TIME} o la mañana del día
 *       ({@link ReminderOptions#taskTiming()}); por la mañana y con resumen, va dentro del resumen. Categoría de
 *       hitos. Al tocarlo se abre el reto.</li>
 *   <li>Resumen de la mañana ({@link ReminderKind#MORNING_SUMMARY}): a la hora elegida (8:00 por defecto), solo si
 *       ese día hay algo después de esa hora (estudios, entrenos, clases, eventos personales, entregas o tareas de
 *       reto). Absorbe el aviso del registro diario de ese día ({@link ReminderKind#CHECK_IN}): llega uno solo, que
 *       también lo recuerda. Cuenta en el límite diario como cualquier otro.</li>
 *   <li>Cumpleaños ({@link ReminderKind#BIRTHDAY}, ADR 0036): si la cuenta tiene fecha de nacimiento, la mañana de su
 *       cumpleaños (el 28 de febrero en los años no bisiestos para quien nació un 29) a la hora del resumen de la
 *       mañana o, sin resumen, a las {@link #BIRTHDAY_TIME}, retrasado por las horas de silencio. Si ese día hay
 *       resumen, la felicitación va dentro de él: nunca dos avisos a la vez. No tiene categoría propia: llega si la
 *       persona admite alguna ({@link #admitsAny}).</li>
 *   <li>Categorías: repasos y estudio usan {@link NotificationType#ACADEMIC}; «hora de entrenar»,
 *       {@link #TRAINING_CATEGORY} ({@code MILESTONE}), porque no hay categoría de deporte y cumplir la
 *       sesión planificada es un hito del plan. Así el modo exámenes la silencia y deja el estudio.</li>
 *   <li>Categoría y modo con {@link NotificationPreferences#admits}; enfoque con
 *       {@link ActivityType#visibleFor} (los repasos cuentan como {@link ActivityType#REVIEW}).</li>
 *   <li>Horas de silencio: a diferencia de las notificaciones de la app (que se descartan porque ya
 *       ocurrieron), un recordatorio se retrasa al final del silencio
 *       ({@link NotificationPreferences#afterQuietHours}); el de un evento o una tarea se descarta si llegaría a
 *       la hora de empezar o después.</li>
 *   <li>Límite diario: como mucho {@code dailyLimit} avisos por día local, por orden de hora; 0 deja
 *       pasar solo las críticas, y un recordatorio nunca lo es, así que no hay avisos.</li>
 *   <li>Tope total de {@link #DEFAULT_MAX_REMINDERS}: iOS solo guarda 64 avisos pendientes por app.</li>
 *   <li>Seguimiento (ver {@link FollowUps}): «tocaba ayer» a las {@link #FOLLOW_UP_TIME} del día siguiente al
 *       previsto para el próximo día de rutina; «¿terminaste la sesión?» {@link #OPEN_SESSION_AFTER} después de
 *       empezar una sesión que sigue abierta (más allá ya cuenta como abandonada y la app lo pregunta al
 *       entrar); «tu reto vence mañana» a las {@link #DEADLINE_TIME} del día antes de su fin. Los dos primeros
 *       son de entrenamiento ({@link #TRAINING_CATEGORY}, enfoque con deporte); el del reto, de hitos.</li>
 * </ul>
 */
public final class ReminderPlanner {

    public static final NotificationType STUDY_CATEGORY = NotificationType.ACADEMIC;
    public static final NotificationType TRAINING_CATEGORY = NotificationType.MILESTONE;
    public static final LocalTime REVIEW_TIME = LocalTime.of(19, 0);
    public static final int REVIEW_DAYS = 3;
    public static final int MAX_DAYS = 7;
    public static final int DEFAULT_MAX_REMINDERS = 60;
    public static final LocalTime DEADLINE_TIME = LocalTime.of(18, 0);
    public static final LocalTime WEEKLY_TIME = LocalTime.of(20, 0);
    /**
     * Hora del aviso de una tarea de reto «la mañana del día» cuando no hay resumen de la mañana que la lleve: la
     * misma que el resumen por defecto, para que ambos avisos se sientan uno solo.
     */
    public static final LocalTime TASK_MORNING_TIME = ReminderOptions.DEFAULT_SUMMARY_AT;
    public static final LocalTime FOLLOW_UP_TIME = LocalTime.of(10, 0);
    /** Hora de la felicitación si la persona no tiene resumen de la mañana. */
    public static final LocalTime BIRTHDAY_TIME = LocalTime.of(9, 0);
    public static final Duration OPEN_SESSION_AFTER = Duration.ofHours(2);

    private final int maxReminders;

    public ReminderPlanner() {
        this(DEFAULT_MAX_REMINDERS);
    }

    public ReminderPlanner(int maxReminders) {
        this.maxReminders = maxReminders;
    }

    /**
     * Bloque del planificador candidato a aviso.
     *
     * @param title temas del bloque o, si no hay, su asignatura; nulo si no tiene ninguno
     */
    public record Block(UUID id, ActivityType type, Instant start, String title, boolean completed) {
    }

    /** Entrega o examen pendiente, candidato a aviso. */
    public record Deadline(UUID id, boolean exam, String title, Instant dueAt) {
    }

    /** Próximo día de rutina pendiente y la fecha en que tocaba. */
    public record RoutineDay(UUID dayId, String title, LocalDate scheduledDate) {
    }

    /** Sesión de entrenamiento abierta. */
    public record OpenSession(UUID sessionId, String title, Instant startedAt) {
    }

    /** Reto sin completar y su fin. */
    public record ChallengeDue(UUID challengeId, String title, Instant endAt) {
    }

    /** Fecha de nacimiento y nombre con el que se felicita («¡Feliz cumpleaños, Ana!»). */
    public record Birthday(BirthDate date, String name) {
    }

    /** Lo que se sigue después de planificar: día de rutina, sesiones abiertas y retos (vacío si no aplica). */
    public record FollowUps(RoutineDay routineDay, List<OpenSession> openSessions, List<ChallengeDue> challenges) {

        public static final FollowUps NONE = new FollowUps(null, List.of(), List.of());

        public FollowUps {
            openSessions = List.copyOf(openSessions);
            challenges = List.copyOf(challenges);
        }
    }

    /**
     * Datos del plan.
     *
     * @param dueReviews repasos vencidos ahora
     * @param blocks     bloques que se solapan con la ventana [now, now + days)
     * @param days       ventana en días (1..{@link #MAX_DAYS})
     * @param deadlines  entregas y exámenes pendientes que vencen antes de {@link #deadlineHorizon}
     * @param weeklySummary incluir el aviso «Tu semana» del domingo
     * @param options    antelaciones y resumen de la mañana elegidos (nulas: por defecto)
     * @param tasks      tareas de reto pendientes con fecha ({@link DatedTask})
     * @param birthday   fecha de nacimiento y nombre, o {@code null} si no la ha dado
     */
    public record Input(int dueReviews, List<Block> blocks, NotificationPreferences preferences, UsageFocus focus,
                        Instant now, ZoneId zone, int days, List<Deadline> deadlines, boolean weeklySummary,
                        FollowUps followUps, ReminderOptions options, List<DatedTask> tasks, Birthday birthday) {

        public Input {
            followUps = followUps == null ? FollowUps.NONE : followUps;
            options = options == null ? ReminderOptions.DEFAULTS : options;
            tasks = tasks == null ? List.of() : List.copyOf(tasks);
        }

        public Input(int dueReviews, List<Block> blocks, NotificationPreferences preferences, UsageFocus focus,
                     Instant now, ZoneId zone, int days, List<Deadline> deadlines, boolean weeklySummary,
                     FollowUps followUps, ReminderOptions options, List<DatedTask> tasks) {
            this(dueReviews, blocks, preferences, focus, now, zone, days, deadlines, weeklySummary, followUps,
                    options, tasks, null);
        }

        public Input(int dueReviews, List<Block> blocks, NotificationPreferences preferences, UsageFocus focus,
                     Instant now, ZoneId zone, int days, List<Deadline> deadlines, boolean weeklySummary,
                     FollowUps followUps) {
            this(dueReviews, blocks, preferences, focus, now, zone, days, deadlines, weeklySummary, followUps,
                    ReminderOptions.DEFAULTS, List.of());
        }

        public Input(int dueReviews, List<Block> blocks, NotificationPreferences preferences, UsageFocus focus,
                     Instant now, ZoneId zone, int days, List<Deadline> deadlines, boolean weeklySummary) {
            this(dueReviews, blocks, preferences, focus, now, zone, days, deadlines, weeklySummary, FollowUps.NONE);
        }

        public Input(int dueReviews, List<Block> blocks, NotificationPreferences preferences, UsageFocus focus,
                     Instant now, ZoneId zone, int days) {
            this(dueReviews, blocks, preferences, focus, now, zone, days, List.of(), false);
        }
    }

    /** Hasta dónde hace falta leer entregas: la que vence justo después de la ventana aún se avisa antes. */
    public static Instant deadlineHorizon(Instant now, int days) {
        int maxBefore = ReminderOptions.DEADLINE_DAY_OPTIONS.stream().mapToInt(Integer::intValue).max().orElse(0);
        return horizonEnd(now, days).plus(Duration.ofDays(maxBefore + 1L));
    }

    /** Fin de la ventana del plan; valida {@code days} (1..{@link #MAX_DAYS}). */
    public static Instant horizonEnd(Instant now, int days) {
        return now.plus(Duration.ofDays(Guard.range(days, "days", 1, MAX_DAYS)));
    }

    /** ¿Hace falta contar los repasos vencidos? Evita leer datos que no se van a avisar. */
    public static boolean wantsReviews(NotificationPreferences preferences, UsageFocus focus) {
        return preferences.dailyLimit() > 0 && allows(ActivityType.REVIEW, preferences, focus);
    }

    /** ¿Hace falta leer entregas y exámenes? */
    public static boolean wantsDeadlines(NotificationPreferences preferences, UsageFocus focus) {
        return preferences.dailyLimit() > 0 && (allows(ActivityType.EXAM, preferences, focus)
                || allows(ActivityType.DELIVERY, preferences, focus));
    }

    /**
     * ¿Hace falta leer los eventos del planificador? Casi siempre: además de sus avisos, los usan el resumen de la
     * mañana y las tareas de reto.
     */
    public static boolean wantsBlocks(NotificationPreferences preferences, UsageFocus focus) {
        return preferences.dailyLimit() > 0 && (allows(ActivityType.STUDY, preferences, focus)
                || allows(ActivityType.SPORT, preferences, focus) || admitsAny(preferences));
    }

    /** ¿Admite la persona alguna categoría? Sirve a lo que no tiene categoría propia (eventos personales). */
    public static boolean admitsAny(NotificationPreferences preferences) {
        return Arrays.stream(NotificationType.values()).anyMatch(preferences::admits);
    }

    public ReminderPlan plan(Input input) {
        return plan(input, List.of());
    }

    /**
     * Igual, sumando avisos ya decididos fuera (los de bienestar, {@link WellbeingReminders}) antes del límite
     * diario y del tope total: así todos compiten por los mismos huecos del día.
     */
    public ReminderPlan plan(Input input, List<ReminderPlan.Item> extra) {
        Instant end = horizonEnd(input.now(), input.days());
        if (input.preferences().dailyLimit() <= 0) {
            return ReminderPlan.empty();
        }
        List<ReminderPlan.Item> candidates = new ArrayList<>();
        if (input.dueReviews() > 0 && wantsReviews(input.preferences(), input.focus())) {
            addReviews(candidates, input, end);
        }
        addBlocks(candidates, input, end);
        addDeadlines(candidates, input, end);
        if (input.weeklySummary()) {
            addWeeklySummary(candidates, input, end);
        }
        addFollowUps(candidates, input, end);
        addBirthday(candidates, input, end);
        candidates.addAll(extra);
        candidates = mentionTasks(candidates, input, end);
        addMorningSummaries(candidates, input, end);
        candidates = absorbCheckIns(candidates, input.zone());
        candidates = absorbBirthdays(candidates, input.zone());
        candidates.sort(Comparator.comparing(ReminderPlan.Item::at));
        return new ReminderPlan(applyDailyLimit(candidates, input.preferences().dailyLimit(), input.zone())
                .stream().limit(maxReminders).toList());
    }

    /**
     * Sin duplicados: cada aviso de una entrega o un evento menciona las tareas de reto que avanzan con él; las tareas
     * que ningún aviso menciona reciben el suyo (o van en el resumen de la mañana).
     */
    private static List<ReminderPlan.Item> mentionTasks(List<ReminderPlan.Item> items, Input input, Instant end) {
        if (input.tasks().isEmpty()) {
            return items;
        }
        Set<DatedTask> covered = new HashSet<>();
        List<ReminderPlan.Item> out = new ArrayList<>(items.size());
        for (ReminderPlan.Item item : items) {
            String anchor = anchorOf(item);
            List<DatedTask> mentioned = anchor == null ? List.of() : input.tasks().stream()
                    .filter(t -> t.anchorId().toString().equals(anchor)).toList();
            covered.addAll(mentioned);
            out.add(mentioned.isEmpty() ? item : item.withTasks(mentioned.stream().map(DatedTask::mention).toList()));
        }
        if (!input.preferences().admits(NotificationType.MILESTONE)) {
            return out;
        }
        ReminderOptions options = input.options();
        boolean morning = options.taskTiming() == ReminderOptions.TaskTiming.MORNING_OF;
        for (DatedTask task : input.tasks()) {
            LocalDate taskDay = task.at().atZone(input.zone()).toLocalDate();
            // Por la mañana y con resumen antes de la tarea, va dentro del resumen de ese día.
            if (covered.contains(task) || (morning && options.morningSummary()
                    && deferQuietHours(ZonedDateTime.of(taskDay, options.morningSummaryAt(), input.zone()), input)
                    .isBefore(dueOf(task, input.zone())))) {
                continue;
            }
            ZonedDateTime planned = morning
                    ? ZonedDateTime.of(taskDay, TASK_MORNING_TIME, input.zone())
                    : ZonedDateTime.of(taskDay.minusDays(1), DEADLINE_TIME, input.zone());
            Instant at = deferQuietHours(planned, input);
            if (!at.isAfter(input.now()) || at.isAfter(end) || !at.isBefore(dueOf(task, input.zone()))) {
                continue;
            }
            int daysLeft = (int) ChronoUnit.DAYS.between(at.atZone(input.zone()).toLocalDate(), taskDay);
            String ref = (task.milestoneId() == null ? task.challengeId() : task.milestoneId()) + ":"
                    + options.taskTiming().name();
            out.add(new ReminderPlan.Item(ReminderKind.CHALLENGE_TASK, at, ref, daysLeft, task.title(), task.at(),
                    task.challengeId().toString(), null, List.of(task.mention()), null));
        }
        return out;
    }

    /** Id de la entrega o el evento del que avisa un aviso (con el que se cruzan las tareas de reto). */
    private static String anchorOf(ReminderPlan.Item item) {
        return switch (item.kind()) {
            case EXAM, DEADLINE -> item.targetId();
            case STUDY, TRAINING, PERSONAL_EVENT, CLASS_SOON -> item.refId();
            default -> null;
        };
    }

    /** Hasta cuándo sirve avisar de una tarea: su hora o, si solo tiene día (rutina), el final de ese día. */
    private static Instant dueOf(DatedTask task, ZoneId zone) {
        if (task.anchor() != DatedTask.Anchor.ROUTINE_DAY) {
            return task.at();
        }
        return task.at().atZone(zone).toLocalDate().plusDays(1).atStartOfDay(zone).toInstant();
    }

    /**
     * Un resumen por cada mañana de la ventana que tenga algo después de la hora del resumen. Los eventos y las
     * entregas se cuentan una vez; una tarea de reto, solo si no va ya con uno de ellos.
     */
    private static void addMorningSummaries(List<ReminderPlan.Item> out, Input input, Instant end) {
        LocalTime time = input.options().morningSummaryAt();
        NotificationPreferences prefs = input.preferences();
        if (time == null || !(prefs.admits(STUDY_CATEGORY) || prefs.admits(TRAINING_CATEGORY))) {
            return;
        }
        ZoneId zone = input.zone();
        LocalDate last = end.atZone(zone).toLocalDate();
        for (LocalDate day = input.now().atZone(zone).toLocalDate(); !day.isAfter(last); day = day.plusDays(1)) {
            Instant at = deferQuietHours(ZonedDateTime.of(day, time, zone), input);
            if (!at.isAfter(input.now()) || at.isAfter(end)) {
                continue;
            }
            ReminderPlan.DaySummary summary = summaryOf(input, day, at);
            if (!summary.isEmpty()) {
                LocalDate summaryDay = day;
                List<TaskMention> tasks = summary.tasks() == 0 ? List.of() : input.tasks().stream()
                        .filter(t -> t.at().atZone(zone).toLocalDate().equals(summaryDay))
                        .filter(t -> !dueOf(t, zone).isBefore(at))
                        .map(DatedTask::mention).toList();
                out.add(new ReminderPlan.Item(ReminderKind.MORNING_SUMMARY, at, day.toString(), null, null, null,
                        null, null, tasks, summary));
            }
        }
    }

    /** Lo que trae {@code day} desde {@code from} (la hora del resumen) hasta el final del día. */
    static ReminderPlan.DaySummary summaryOf(Input input, LocalDate day, Instant from) {
        ZoneId zone = input.zone();
        Instant dayEnd = day.plusDays(1).atStartOfDay(zone).toInstant();
        Set<String> counted = new HashSet<>();
        int studies = 0;
        int trainings = 0;
        int classes = 0;
        int personal = 0;
        for (Block b : input.blocks()) {
            if (b.completed() || b.start().isBefore(from) || !b.start().isBefore(dayEnd)
                    || !b.type().visibleFor(input.focus())) {
                continue;
            }
            switch (b.type()) {
                case STUDY, REVIEW -> studies++;
                case SPORT -> trainings++;
                case CLASS -> classes++;
                case PERSONAL -> personal++;
                default -> {
                    continue;
                }
            }
            counted.add(b.id().toString());
        }
        List<ReminderPlan.SummaryDeadline> deadlines = new ArrayList<>();
        for (Deadline d : input.deadlines()) {
            if (!d.dueAt().isBefore(from) && d.dueAt().isBefore(dayEnd)) {
                deadlines.add(new ReminderPlan.SummaryDeadline(d.title(), d.exam()));
                counted.add(d.id().toString());
            }
        }
        int tasks = input.preferences().admits(NotificationType.MILESTONE) ? (int) input.tasks().stream()
                .filter(t -> !counted.contains(t.anchorId().toString()))
                .filter(t -> t.at().atZone(zone).toLocalDate().equals(day))
                .filter(t -> !dueOf(t, zone).isBefore(from))
                .count() : 0;
        return new ReminderPlan.DaySummary(studies, trainings, classes, personal, deadlines, tasks, false);
    }

    /**
     * El resumen y el registro diario son los dos avisos de la mañana: si un día hay resumen, el registro va dentro
     * de él en vez de llegar aparte (ADR 0035). Sin resumen ese día, el registro llega solo a su hora.
     */
    private static List<ReminderPlan.Item> absorbCheckIns(List<ReminderPlan.Item> items, ZoneId zone) {
        Set<LocalDate> summaryDays = new HashSet<>();
        Set<LocalDate> checkInDays = new HashSet<>();
        for (ReminderPlan.Item i : items) {
            if (i.kind() == ReminderKind.MORNING_SUMMARY) {
                summaryDays.add(i.at().atZone(zone).toLocalDate());
            } else if (i.kind() == ReminderKind.CHECK_IN) {
                checkInDays.add(i.at().atZone(zone).toLocalDate());
            }
        }
        List<ReminderPlan.Item> out = new ArrayList<>(items.size());
        for (ReminderPlan.Item i : items) {
            LocalDate day = i.at().atZone(zone).toLocalDate();
            if (i.kind() == ReminderKind.CHECK_IN && summaryDays.contains(day)) {
                continue;
            }
            out.add(i.kind() == ReminderKind.MORNING_SUMMARY && checkInDays.contains(day) ? i.withCheckIn() : i);
        }
        return out;
    }

    /** La felicitación de cada cumpleaños que cae en la ventana (como mucho uno: la ventana es de una semana). */
    private static void addBirthday(List<ReminderPlan.Item> out, Input input, Instant end) {
        Birthday birthday = input.birthday();
        if (birthday == null || !admitsAny(input.preferences())) {
            return;
        }
        LocalTime summaryAt = input.options().morningSummaryAt();
        LocalTime time = input.options().morningSummary() && summaryAt != null ? summaryAt : BIRTHDAY_TIME;
        ZoneId zone = input.zone();
        LocalDate last = end.atZone(zone).toLocalDate();
        for (LocalDate day = input.now().atZone(zone).toLocalDate(); !day.isAfter(last); day = day.plusDays(1)) {
            if (!birthday.date().isBirthday(day)) {
                continue;
            }
            Instant at = deferQuietHours(ZonedDateTime.of(day, time, zone), input);
            // Por la mañana: si el silencio la empuja a otro día, ya no es una felicitación de ese día.
            if (at.isAfter(input.now()) && !at.isAfter(end) && at.atZone(zone).toLocalDate().equals(day)) {
                out.add(new ReminderPlan.Item(ReminderKind.BIRTHDAY, at, day.toString(), null, birthday.name(),
                        null));
            }
        }
    }

    /**
     * El resumen de la mañana y la felicitación son dos avisos de la mañana: si un día hay resumen, la felicitación va
     * dentro de él (ADR 0036). Sin resumen ese día, la felicitación llega sola.
     */
    private static List<ReminderPlan.Item> absorbBirthdays(List<ReminderPlan.Item> items, ZoneId zone) {
        Map<LocalDate, String> birthdays = new HashMap<>();
        Set<LocalDate> summaryDays = new HashSet<>();
        for (ReminderPlan.Item i : items) {
            LocalDate day = i.at().atZone(zone).toLocalDate();
            if (i.kind() == ReminderKind.BIRTHDAY) {
                birthdays.put(day, i.title());
            } else if (i.kind() == ReminderKind.MORNING_SUMMARY) {
                summaryDays.add(day);
            }
        }
        if (birthdays.isEmpty()) {
            return items;
        }
        List<ReminderPlan.Item> out = new ArrayList<>(items.size());
        for (ReminderPlan.Item i : items) {
            LocalDate day = i.at().atZone(zone).toLocalDate();
            if (i.kind() == ReminderKind.BIRTHDAY && summaryDays.contains(day)) {
                continue;
            }
            out.add(i.kind() == ReminderKind.MORNING_SUMMARY && birthdays.containsKey(day)
                    ? i.withBirthday(birthdays.get(day)) : i);
        }
        return out;
    }

    private static void addReviews(List<ReminderPlan.Item> out, Input input, Instant end) {
        LocalDate today = input.now().atZone(input.zone()).toLocalDate();
        int produced = 0;
        // Hoy cuenta solo si aún no ha pasado la hora; por eso se mira un día más.
        for (int offset = 0; offset <= REVIEW_DAYS && produced < REVIEW_DAYS; offset++) {
            LocalDate day = today.plusDays(offset);
            ZonedDateTime planned = ZonedDateTime.of(day, REVIEW_TIME, input.zone());
            if (!planned.toInstant().isAfter(input.now())) {
                continue;
            }
            Instant at = deferQuietHours(planned, input);
            if (at.isAfter(end)) {
                break;
            }
            produced++;
            out.add(new ReminderPlan.Item(ReminderKind.REVIEWS, at, day.toString(), input.dueReviews(), null,
                    null));
        }
    }

    private static void addBlocks(List<ReminderPlan.Item> out, Input input, Instant end) {
        for (Block block : input.blocks()) {
            ReminderKind kind = kindOf(block.type());
            if (kind == null || block.completed() || !allows(block.type(), input.preferences(), input.focus())) {
                continue;
            }
            if (!block.start().isAfter(input.now()) || block.start().isAfter(end)) {
                continue;
            }
            Duration lead = Duration.ofMinutes(input.options().eventLeadMinutes());
            Instant at = deferQuietHours(block.start().minus(lead).atZone(input.zone()), input);
            // Si el aviso ya pasó o el silencio lo empuja hasta el inicio, sobra.
            if (!at.isAfter(input.now()) || !at.isBefore(block.start())) {
                continue;
            }
            out.add(new ReminderPlan.Item(kind, at, block.id().toString(), null, block.title(), block.start()));
        }
    }

    private static void addDeadlines(List<ReminderPlan.Item> out, Input input, Instant end) {
        for (Deadline deadline : input.deadlines()) {
            ActivityType type = deadline.exam() ? ActivityType.EXAM : ActivityType.DELIVERY;
            if (!allows(type, input.preferences(), input.focus())) {
                continue;
            }
            LocalDate dueDay = deadline.dueAt().atZone(input.zone()).toLocalDate();
            for (int daysBefore : input.options().deadlineDaysBefore()) {
                ZonedDateTime planned = ZonedDateTime.of(dueDay.minusDays(daysBefore), DEADLINE_TIME, input.zone());
                Instant at = deferQuietHours(planned, input);
                if (!at.isAfter(input.now()) || at.isAfter(end) || !at.isBefore(deadline.dueAt())) {
                    continue;
                }
                // Días que faltan desde el aviso real (el silencio puede haberlo movido al día siguiente).
                int daysLeft = (int) ChronoUnit.DAYS.between(
                        at.atZone(input.zone()).toLocalDate(), dueDay);
                out.add(new ReminderPlan.Item(deadline.exam() ? ReminderKind.EXAM : ReminderKind.DEADLINE, at,
                        deadline.id() + ":" + daysBefore, daysLeft, deadline.title(), deadline.dueAt(),
                        deadline.id().toString(), null));
            }
        }
    }

    private static void addWeeklySummary(List<ReminderPlan.Item> out, Input input, Instant end) {
        NotificationPreferences prefs = input.preferences();
        if (!prefs.admits(STUDY_CATEGORY) && !prefs.admits(TRAINING_CATEGORY)) {
            return;
        }
        LocalDate day = input.now().atZone(input.zone()).toLocalDate()
                .with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY));
        ZonedDateTime planned = ZonedDateTime.of(day, WEEKLY_TIME, input.zone());
        if (!planned.toInstant().isAfter(input.now())) {
            planned = planned.plusWeeks(1);
        }
        Instant at = deferQuietHours(planned, input);
        if (at.isAfter(input.now()) && !at.isAfter(end)) {
            out.add(new ReminderPlan.Item(ReminderKind.WEEKLY_SUMMARY, at, planned.toLocalDate().toString(), null,
                    null, null));
        }
    }

    private static void addFollowUps(List<ReminderPlan.Item> out, Input input, Instant end) {
        FollowUps f = input.followUps();
        boolean training = allows(ActivityType.SPORT, input.preferences(), input.focus());
        if (training && f.routineDay() != null) {
            ZonedDateTime planned = ZonedDateTime.of(f.routineDay().scheduledDate().plusDays(1), FOLLOW_UP_TIME,
                    input.zone());
            addIfInWindow(out, input, end, ReminderKind.ROUTINE_DAY_MISSED, deferQuietHours(planned, input),
                    f.routineDay().dayId().toString(), f.routineDay().title(),
                    f.routineDay().scheduledDate().atStartOfDay(input.zone()).toInstant());
        }
        if (training) {
            for (OpenSession s : f.openSessions()) {
                Instant at = deferQuietHours(s.startedAt().plus(OPEN_SESSION_AFTER).atZone(input.zone()), input);
                addIfInWindow(out, input, end, ReminderKind.OPEN_SESSION, at, s.sessionId().toString(), s.title(),
                        s.startedAt());
            }
        }
        if (input.preferences().admits(NotificationType.MILESTONE)) {
            for (ChallengeDue c : f.challenges()) {
                LocalDate endDay = c.endAt().atZone(input.zone()).toLocalDate();
                Instant at = deferQuietHours(ZonedDateTime.of(endDay.minusDays(1), DEADLINE_TIME, input.zone()),
                        input);
                if (at.isBefore(c.endAt())) {
                    addIfInWindow(out, input, end, ReminderKind.CHALLENGE_DUE, at, c.challengeId().toString(),
                            c.title(), c.endAt());
                }
            }
        }
    }

    private static void addIfInWindow(List<ReminderPlan.Item> out, Input input, Instant end, ReminderKind kind,
                                      Instant at, String refId, String title, Instant startsAt) {
        if (at.isAfter(input.now()) && !at.isAfter(end)) {
            out.add(new ReminderPlan.Item(kind, at, refId, null, title, startsAt));
        }
    }

    private static ReminderKind kindOf(ActivityType type) {
        return switch (type) {
            case SPORT -> ReminderKind.TRAINING;
            case STUDY, REVIEW -> ReminderKind.STUDY;
            case PERSONAL -> ReminderKind.PERSONAL_EVENT;
            default -> null;
        };
    }

    /** Categoría y modo de las preferencias más el ámbito del enfoque de uso. */
    private static boolean allows(ActivityType type, NotificationPreferences preferences, UsageFocus focus) {
        if (type == ActivityType.PERSONAL) {
            return admitsAny(preferences);
        }
        NotificationType category = type == ActivityType.SPORT ? TRAINING_CATEGORY : STUDY_CATEGORY;
        return type.visibleFor(focus) && preferences.admits(category);
    }

    private static Instant deferQuietHours(ZonedDateTime at, Input input) {
        LocalDateTime local = input.preferences().afterQuietHours(at.toLocalDateTime());
        return local.equals(at.toLocalDateTime()) ? at.toInstant() : local.atZone(input.zone()).toInstant();
    }

    /** Deja los primeros {@code limit} avisos de cada día local (la lista llega ordenada por hora). */
    private static List<ReminderPlan.Item> applyDailyLimit(List<ReminderPlan.Item> sorted, int limit, ZoneId zone) {
        Map<LocalDate, Integer> perDay = new HashMap<>();
        List<ReminderPlan.Item> kept = new ArrayList<>();
        for (ReminderPlan.Item item : sorted) {
            if (perDay.merge(item.at().atZone(zone).toLocalDate(), 1, Integer::sum) <= limit) {
                kept.add(item);
            }
        }
        return kept;
    }
}
