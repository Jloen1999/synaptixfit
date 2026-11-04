package com.synaptixfit.domain.model.notification;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Avisos de bienestar del plan de recordatorios (ADR 0013 y 0033), que se suman a los de {@link ReminderPlanner}
 * antes del límite diario. Lógica pura.
 *
 * <ul>
 *   <li>Racha en riesgo: hoy a las {@link #STREAK_TIME} si hay racha y aún no hay actividad hoy. Categoría de hitos
 *       ({@link NotificationType#MILESTONE}): la racha es un logro.</li>
 *   <li>Registro diario: a las {@link #CHECK_IN_TIME} de cada día de la ventana; hoy solo si aún no se ha hecho.
 *       Categoría de fatiga ({@link NotificationType#FATIGUE_ALERT}): el registro mide la fatiga.</li>
 *   <li>Clase a punto de empezar: {@link ReminderPlanner#LEAD_TIME} antes, con el aula. Categoría académica y
 *       enfoque que muestre las clases. Se descartan las completadas o marcadas como «No fui».</li>
 * </ul>
 * Cada uno se puede apagar en {@link ReminderOptions}. Las horas de silencio retrasan el aviso como en el resto;
 * el de la clase se descarta si llegaría a la hora de empezar o después.
 */
public final class WellbeingReminders {

    public static final LocalTime STREAK_TIME = LocalTime.of(20, 0);
    public static final LocalTime CHECK_IN_TIME = LocalTime.of(9, 0);

    private WellbeingReminders() {
    }

    /** Clase del planificador candidata a aviso; {@code place} es el aula (nula si no se sabe). */
    public record ClassBlock(UUID id, String title, String place, Instant start, boolean done) {
    }

    /**
     * @param streakDays       días de la racha actual
     * @param activeToday      hoy ya cuenta para la racha
     * @param checkInDoneToday hoy ya hay registro diario
     */
    public record Input(NotificationPreferences preferences, UsageFocus focus, ReminderOptions options, Instant now,
                        ZoneId zone, Instant end, int streakDays, boolean activeToday, boolean checkInDoneToday,
                        List<ClassBlock> classes) {

        public Input {
            classes = classes == null ? List.of() : List.copyOf(classes);
        }
    }

    public static List<ReminderPlan.Item> plan(Input in) {
        List<ReminderPlan.Item> out = new ArrayList<>();
        if (in.preferences().dailyLimit() <= 0) {
            return out;
        }
        LocalDate today = in.now().atZone(in.zone()).toLocalDate();
        if (in.options().streak() && in.streakDays() > 0 && !in.activeToday()
                && in.preferences().admits(NotificationType.MILESTONE)) {
            addIfInWindow(out, in, ReminderKind.STREAK_AT_RISK, at(today, STREAK_TIME, in), today.toString(),
                    in.streakDays(), null, null);
        }
        if (in.options().checkIn() && in.preferences().admits(NotificationType.FATIGUE_ALERT)) {
            LocalDate last = in.end().atZone(in.zone()).toLocalDate();
            for (LocalDate day = in.checkInDoneToday() ? today.plusDays(1) : today; !day.isAfter(last);
                 day = day.plusDays(1)) {
                addIfInWindow(out, in, ReminderKind.CHECK_IN, at(day, CHECK_IN_TIME, in), day.toString(), null, null,
                        null);
            }
        }
        if (in.options().classes() && ActivityType.CLASS.visibleFor(in.focus())
                && in.preferences().admits(ReminderPlanner.STUDY_CATEGORY)) {
            for (ClassBlock c : in.classes()) {
                if (c.done() || !c.start().isAfter(in.now()) || c.start().isAfter(in.end())) {
                    continue;
                }
                Instant at = deferQuietHours(c.start().minus(ReminderPlanner.LEAD_TIME).atZone(in.zone()), in);
                if (at.isAfter(in.now()) && at.isBefore(c.start())) {
                    out.add(new ReminderPlan.Item(ReminderKind.CLASS_SOON, at, c.id().toString(), null, c.title(),
                            c.start(), c.place()));
                }
            }
        }
        return out;
    }

    private static Instant at(LocalDate day, LocalTime time, Input in) {
        return deferQuietHours(ZonedDateTime.of(day, time, in.zone()), in);
    }

    private static void addIfInWindow(List<ReminderPlan.Item> out, Input in, ReminderKind kind, Instant at,
                                      String refId, Integer count, String title, Instant startsAt) {
        if (at.isAfter(in.now()) && !at.isAfter(in.end())) {
            out.add(new ReminderPlan.Item(kind, at, refId, count, title, startsAt));
        }
    }

    private static Instant deferQuietHours(ZonedDateTime at, Input in) {
        LocalDateTime local = in.preferences().afterQuietHours(at.toLocalDateTime());
        return local.equals(at.toLocalDateTime()) ? at.toInstant() : local.atZone(in.zone()).toInstant();
    }
}
