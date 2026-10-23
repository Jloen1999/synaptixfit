package com.synaptixfit.domain.model.notification;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
 *   <li>Bloques de deporte, estudio y repaso: 15 minutos antes de empezar. Se descartan los
 *       completados, los ya empezados y el resto de tipos (clases, exámenes, entregas…).</li>
 *   <li>Categorías: repasos y estudio usan {@link NotificationType#ACADEMIC}; «hora de entrenar»,
 *       {@link #TRAINING_CATEGORY} ({@code MILESTONE}), porque no hay categoría de deporte y cumplir la
 *       sesión planificada es un hito del plan. Así el modo exámenes la silencia y deja el estudio.</li>
 *   <li>Categoría y modo con {@link NotificationPreferences#admits}; enfoque con
 *       {@link ActivityType#visibleFor} (los repasos cuentan como {@link ActivityType#REVIEW}).</li>
 *   <li>Horas de silencio: a diferencia de las notificaciones de la app (que se descartan porque ya
 *       ocurrieron), un recordatorio se retrasa al final del silencio
 *       ({@link NotificationPreferences#afterQuietHours}); el de un bloque se descarta si llegaría a la
 *       hora de empezar o después.</li>
 *   <li>Límite diario: como mucho {@code dailyLimit} avisos por día local, por orden de hora; 0 deja
 *       pasar solo las críticas, y un recordatorio nunca lo es, así que no hay avisos.</li>
 *   <li>Tope total de {@link #DEFAULT_MAX_REMINDERS}: iOS solo guarda 64 avisos pendientes por app.</li>
 * </ul>
 */
public final class ReminderPlanner {

    public static final NotificationType STUDY_CATEGORY = NotificationType.ACADEMIC;
    public static final NotificationType TRAINING_CATEGORY = NotificationType.MILESTONE;
    public static final LocalTime REVIEW_TIME = LocalTime.of(19, 0);
    public static final Duration LEAD_TIME = Duration.ofMinutes(15);
    public static final int REVIEW_DAYS = 3;
    public static final int MAX_DAYS = 7;
    public static final int DEFAULT_MAX_REMINDERS = 60;

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

    /**
     * Datos del plan.
     *
     * @param dueReviews repasos vencidos ahora
     * @param blocks     bloques que se solapan con la ventana [now, now + days)
     * @param days       ventana en días (1..{@link #MAX_DAYS})
     */
    public record Input(int dueReviews, List<Block> blocks, NotificationPreferences preferences, UsageFocus focus,
                        Instant now, ZoneId zone, int days) {
    }

    /** Fin de la ventana del plan; valida {@code days} (1..{@link #MAX_DAYS}). */
    public static Instant horizonEnd(Instant now, int days) {
        return now.plus(Duration.ofDays(Guard.range(days, "days", 1, MAX_DAYS)));
    }

    /** ¿Hace falta contar los repasos vencidos? Evita leer datos que no se van a avisar. */
    public static boolean wantsReviews(NotificationPreferences preferences, UsageFocus focus) {
        return preferences.dailyLimit() > 0 && allows(ActivityType.REVIEW, preferences, focus);
    }

    /** ¿Hace falta leer los bloques del planificador? */
    public static boolean wantsBlocks(NotificationPreferences preferences, UsageFocus focus) {
        return preferences.dailyLimit() > 0 && (allows(ActivityType.STUDY, preferences, focus)
                || allows(ActivityType.SPORT, preferences, focus));
    }

    public ReminderPlan plan(Input input) {
        Instant end = horizonEnd(input.now(), input.days());
        if (input.preferences().dailyLimit() <= 0) {
            return ReminderPlan.empty();
        }
        List<ReminderPlan.Item> candidates = new ArrayList<>();
        if (input.dueReviews() > 0 && wantsReviews(input.preferences(), input.focus())) {
            addReviews(candidates, input, end);
        }
        addBlocks(candidates, input, end);
        candidates.sort(Comparator.comparing(ReminderPlan.Item::at));
        return new ReminderPlan(applyDailyLimit(candidates, input.preferences().dailyLimit(), input.zone())
                .stream().limit(maxReminders).toList());
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
            Instant at = deferQuietHours(block.start().minus(LEAD_TIME).atZone(input.zone()), input);
            // Si el aviso ya pasó o el silencio lo empuja hasta el inicio, sobra.
            if (!at.isAfter(input.now()) || !at.isBefore(block.start())) {
                continue;
            }
            out.add(new ReminderPlan.Item(kind, at, block.id().toString(), null, block.title(), block.start()));
        }
    }

    private static ReminderKind kindOf(ActivityType type) {
        return switch (type) {
            case SPORT -> ReminderKind.TRAINING;
            case STUDY, REVIEW -> ReminderKind.STUDY;
            default -> null;
        };
    }

    /** Categoría y modo de las preferencias más el ámbito del enfoque de uso. */
    private static boolean allows(ActivityType type, NotificationPreferences preferences, UsageFocus focus) {
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
