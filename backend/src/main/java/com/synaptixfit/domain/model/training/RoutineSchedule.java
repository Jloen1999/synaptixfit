package com.synaptixfit.domain.model.training;

import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Regla única del «próximo día» de una rutina (la usan Rutinas, Inicio y los avisos).
 *
 * <p>La rutina avanza al ritmo al que se entrena, no por fechas fijas:
 * <ol>
 *   <li>Si un día tiene una sesión en curso (abierta hace menos de {@link TrainingSession#STALE_AFTER}),
 *       ese es el próximo, en curso y para hoy.</li>
 *   <li>Si no, el primer día entrenable (con ejercicios) que no esté hecho ni saltado, recorriendo
 *       semanas y días en orden. Un día «en progreso» cuya sesión se abandonó cuenta como pendiente.</li>
 *   <li>Fecha prevista: la del bloque del calendario enlazado a ese día (si es posterior al último
 *       avance); si no hay, el siguiente día de la semana preferido ({@link RoutineDay#number()},
 *       1 = lunes) a partir del día siguiente al último avance ({@link Routine#lastClosedOn()}), o
 *       desde la fecha de inicio (u hoy) si aún no se ha avanzado.</li>
 *   <li>Va con retraso si esa fecha ya pasó: «tocaba el lunes».</li>
 * </ol>
 */
public final class RoutineSchedule {

    private RoutineSchedule() {
    }

    /** Sesión sin terminar de un día. */
    public record OpenSession(UUID sessionId, Instant startedAt) {
    }

    /**
     * Lo que la regla necesita saber fuera del agregado.
     *
     * @param openSessions sesión sin terminar más reciente por día de rutina
     * @param plannedDates fechas de los bloques pendientes del calendario de cada día de rutina
     */
    public record Context(LocalDate today, Instant now, Map<UUID, OpenSession> openSessions,
                          Map<UUID, List<LocalDate>> plannedDates) {

        public Context {
            openSessions = openSessions == null ? Map.of() : Map.copyOf(openSessions);
            plannedDates = plannedDates == null ? Map.of() : Map.copyOf(plannedDates);
        }

        public static Context of(LocalDate today, Instant now) {
            return new Context(today, now, Map.of(), Map.of());
        }
    }

    /**
     * Fechas en las que toca entrenar de aquí a {@code until} (incluido), en orden: el próximo día en su fecha
     * (hoy si va con retraso o ya está en curso) y los siguientes en su día de la semana preferido, cada uno
     * después del anterior. Es una previsión para pintar la semana; la rutina sigue avanzando al ritmo real. Solo el
     * próximo día mira el calendario: los siguientes van a su día de la semana, porque su bloque puede moverse en
     * cuanto se entrene el anterior.
     */
    static List<LocalDate> upcoming(Routine routine, Context ctx, LocalDate until) {
        Optional<PendingDay> next = next(routine, ctx);
        if (next.isEmpty()) {
            return List.of();
        }
        LocalDate date = next.get().scheduledDate().isBefore(ctx.today()) ? ctx.today() : next.get().scheduledDate();
        List<LocalDate> dates = new ArrayList<>();
        boolean after = false;
        for (Slot slot : slots(routine)) {
            if (slot.day().id().equals(next.get().day().id())) {
                after = true;
            } else if (after && !slot.day().status().isClosed()) {
                date = nextWeekday(date.plusDays(1), slot.day().number());
            } else {
                continue;
            }
            if (date.isAfter(until)) {
                break;
            }
            dates.add(date);
        }
        return dates;
    }

    private static List<Slot> slots(Routine routine) {
        List<Slot> order = new ArrayList<>();
        for (RoutineWeek week : routine.weeks()) {
            List<RoutineDay> trainable = week.trainableDays();
            for (int i = 0; i < trainable.size(); i++) {
                order.add(new Slot(week, trainable.get(i), i + 1, trainable.size()));
            }
        }
        return order;
    }

    static Optional<PendingDay> next(Routine routine, Context ctx) {
        List<Slot> order = slots(routine);
        Optional<Slot> active = order.stream()
                .filter(s -> s.day().status() != ProgressStatus.SKIPPED)
                .filter(s -> isActive(ctx.openSessions().get(s.day().id()), ctx.now()))
                .max(Comparator.comparing(s -> ctx.openSessions().get(s.day().id()).startedAt()));
        if (active.isPresent()) {
            Slot s = active.get();
            return Optional.of(pending(routine, s, ProgressStatus.IN_PROGRESS, ctx.today(), false, null));
        }
        Optional<Slot> first = order.stream().filter(s -> !s.day().status().isClosed()).findFirst();
        if (first.isEmpty()) {
            return Optional.empty();
        }
        Slot s = first.get();
        LocalDate anchor = routine.lastClosedOn().orElse(null);
        LocalDate planned = ctx.plannedDates().getOrDefault(s.day().id(), List.of()).stream()
                .filter(d -> anchor == null || d.isAfter(anchor))
                .min(Comparator.naturalOrder()).orElse(null);
        LocalDate scheduled;
        if (planned != null) {
            scheduled = planned;
        } else {
            LocalDate from = anchor != null ? anchor.plusDays(1)
                    : routine.startDate() != null ? routine.startDate() : ctx.today();
            scheduled = nextWeekday(from, s.day().number());
        }
        OpenSession stale = ctx.openSessions().get(s.day().id());
        return Optional.of(pending(routine, s, ProgressStatus.PENDING, scheduled, scheduled.isBefore(ctx.today()),
                stale == null ? null : stale.sessionId()));
    }

    /** Primera fecha desde {@code from} (incluida) cuyo día de la semana es {@code isoWeekday} (1 = lunes). */
    public static LocalDate nextWeekday(LocalDate from, int isoWeekday) {
        int delta = Math.floorMod(isoWeekday - from.getDayOfWeek().getValue(), 7);
        return from.plusDays(delta);
    }

    private static boolean isActive(OpenSession open, Instant now) {
        return open != null && !TrainingSession.isStaleStart(open.startedAt(), now);
    }

    private static PendingDay pending(Routine routine, Slot s, ProgressStatus status, LocalDate scheduled,
                                      boolean overdue, UUID staleSessionId) {
        return new PendingDay(routine, s.week(), s.day(), status, scheduled, overdue, s.position(), s.count(),
                staleSessionId);
    }

    private record Slot(RoutineWeek week, RoutineDay day, int position, int count) {
    }
}
