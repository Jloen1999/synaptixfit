package com.synaptixfit.domain.model.badge;

import com.synaptixfit.domain.exception.badge.StreakPauseLimitReachedException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Pausa explícita de la racha (ADR 0042): «Pausar racha» en un toque. No se pregunta ni se guarda el motivo, solo las
 * fechas (ningún dato de salud). Un día en pausa sin
 * actividad ni suma ni corta la racha y no gasta días libres ({@link StreakFreezes}); si ese día hay actividad,
 * cuenta como siempre.
 *
 * <p>Topes, para que la racha siga significando constancia: una pausa dura como mucho
 * {@value #MAX_CONSECUTIVE_DAYS} días seguidos y no se pueden pausar más de {@value #MAX_DAYS_PER_WINDOW} días en
 * los últimos {@value #WINDOW_DAYS} días (un trimestre: cubre dos semanas de exámenes o una gripe y un viaje). Empieza
 * hoy y acaba sola; «Reanudar» la corta antes.
 *
 * @param from primer día en pausa
 * @param to   último día en pausa (incluido)
 */
public record StreakPause(UUID id, UUID userId, LocalDate from, LocalDate to, Instant createdAt) {

    public static final int MAX_CONSECUTIVE_DAYS = 7;
    public static final int MAX_DAYS_PER_WINDOW = 14;
    public static final int WINDOW_DAYS = 90;

    public StreakPause {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(from, "from");
        Objects.requireNonNull(to, "to");
        Objects.requireNonNull(createdAt, "createdAt");
    }

    public boolean covers(LocalDate day) {
        return !day.isBefore(from) && !day.isAfter(to);
    }

    /** Días de esta pausa entre {@code start} y {@code end} (ambos incluidos). */
    long daysWithin(LocalDate start, LocalDate end) {
        LocalDate a = from.isAfter(start) ? from : start;
        LocalDate b = to.isBefore(end) ? to : end;
        return a.isAfter(b) ? 0 : ChronoUnit.DAYS.between(a, b) + 1;
    }

    /** La pausa que cubre hoy, si la hay. */
    public static Optional<StreakPause> active(List<StreakPause> pauses, LocalDate today) {
        return pauses.stream().filter(p -> p.covers(today)).findFirst();
    }

    /** Días en pausa hasta hoy (incluido): los que la racha no cuenta ni corta. */
    public static Set<LocalDate> pausedDays(List<StreakPause> pauses, LocalDate today) {
        Set<LocalDate> days = new HashSet<>();
        for (StreakPause p : pauses) {
            for (LocalDate d = p.from(); !d.isAfter(p.to()) && !d.isAfter(today); d = d.plusDays(1)) {
                days.add(d);
            }
        }
        return days;
    }

    /**
     * Días que durará una pausa que empiece hoy: lo que quede de {@value #MAX_DAYS_PER_WINDOW} en los últimos
     * {@value #WINDOW_DAYS} días, sin pasar de {@value #MAX_CONSECUTIVE_DAYS}. Con una pausa en curso, 0.
     */
    public static int daysLeft(List<StreakPause> pauses, LocalDate today) {
        if (active(pauses, today).isPresent()) {
            return 0;
        }
        LocalDate windowStart = today.minusDays(WINDOW_DAYS - 1L);
        long used = pauses.stream().mapToLong(p -> p.daysWithin(windowStart, today.minusDays(1))).sum();
        return (int) Math.max(0, Math.min(MAX_CONSECUTIVE_DAYS, MAX_DAYS_PER_WINDOW - used));
    }

    /**
     * Pausa nueva desde hoy con todos los días que queden.
     *
     * @throws StreakPauseLimitReachedException si no queda ninguno
     */
    public static StreakPause start(UUID userId, List<StreakPause> existing, LocalDate today, Instant now) {
        int days = daysLeft(existing, today);
        if (days <= 0) {
            throw new StreakPauseLimitReachedException();
        }
        return new StreakPause(UUID.randomUUID(), userId, today, today.plusDays(days - 1L), now);
    }

    /**
     * «Reanudar» hoy: la pausa acaba ayer (hoy ya cuenta como un día normal, que no corta hasta que pasa). Vacío si
     * empezó hoy: no queda ningún día en pausa y se borra.
     */
    public Optional<StreakPause> resumedOn(LocalDate today) {
        if (!from.isBefore(today)) {
            return Optional.empty();
        }
        return Optional.of(new StreakPause(id, userId, from, today.minusDays(1), createdAt));
    }
}
