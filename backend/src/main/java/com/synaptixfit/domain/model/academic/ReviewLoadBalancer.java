package com.synaptixfit.domain.model.academic;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Repasos sin picos (ADR 0042, {@code formulas.md}): al fijar la fecha del siguiente repaso SM-2 se mira cuántos
 * repasos tiene ya cada día cercano y se elige el que menos tenga, dentro de un margen pequeño para no estropear el
 * espaciado. Es la idea del «load balancer» de Anki (2024) y del «fuzz» de SuperMemo: un día más o menos no cambia
 * cuánto se recuerda en intervalos largos, pero diez repasos el mismo día sí desaniman.
 *
 * <ul>
 *   <li>Intervalo de 1 día (tras un fallo o el primer acierto): no se mueve. Mañana es mañana.</li>
 *   <li>Intervalo de 2 días: solo puede retrasarse 1 día (nunca adelantar un intervalo ≤ 2: quedaría en «mañana»,
 *       lo mismo que un fallo).</li>
 *   <li>De 3 a {@value #LONG_INTERVAL_DAYS} − 1 días: ±1 día.</li>
 *   <li>{@value #LONG_INTERVAL_DAYS} días o más: ±2 días (como mucho un 14 % del intervalo).</li>
 * </ul>
 * Solo se mueve si otro día del margen tiene <b>menos</b> repasos que el propuesto; con empate gana el más cercano al
 * propuesto y, si siguen empatados, el anterior (repasar antes nunca hace olvidar). El intervalo SM-2 guardado no
 * cambia: solo la fecha, así el algoritmo sigue igual.
 */
public final class ReviewLoadBalancer {

    /** Desde aquí el margen es de ±2 días. */
    public static final int LONG_INTERVAL_DAYS = 14;
    static final int SHORT_SHIFT = 1;
    static final int LONG_SHIFT = 2;

    private ReviewLoadBalancer() {
    }

    /** Repaso ya programado de un material (el que se está repasando se excluye al contar). */
    public record Scheduled(UUID materialId, Instant at) {
    }

    /**
     * Repasos ya programados por día (en la zona de la persona), sin contar el material que se está repasando.
     *
     * @param perDay repasos por día local
     */
    public record Load(Map<LocalDate, Integer> perDay, ZoneId zone) {

        public static final Load NONE = new Load(Map.of(), ZoneId.of("UTC"));

        public Load {
            perDay = Map.copyOf(perDay);
        }

        public static Load of(Collection<Scheduled> scheduled, UUID exclude, ZoneId zone) {
            Map<LocalDate, Integer> counts = new HashMap<>();
            for (Scheduled s : scheduled) {
                if (s.at() != null && !s.materialId().equals(exclude)) {
                    counts.merge(LocalDate.ofInstant(s.at(), zone), 1, Integer::sum);
                }
            }
            return new Load(counts, zone);
        }

        int on(LocalDate day) {
            return perDay.getOrDefault(day, 0);
        }
    }

    /** Días que se puede adelantar el repaso. */
    public static int maxAdvance(int intervalDays) {
        if (intervalDays <= 2) {
            return 0;
        }
        return intervalDays >= LONG_INTERVAL_DAYS ? LONG_SHIFT : SHORT_SHIFT;
    }

    /** Días que se puede retrasar el repaso. */
    public static int maxDelay(int intervalDays) {
        if (intervalDays <= 1) {
            return 0;
        }
        return intervalDays >= LONG_INTERVAL_DAYS ? LONG_SHIFT : SHORT_SHIFT;
    }

    /** Ventana de días (desde {@code from}) que hay que leer para equilibrar un repaso que vence en {@code proposed}. */
    public static Instant windowStart(Instant proposed) {
        return proposed.minus(LONG_SHIFT + 1, ChronoUnit.DAYS);
    }

    public static Instant windowEnd(Instant proposed) {
        return proposed.plus(LONG_SHIFT + 1, ChronoUnit.DAYS);
    }

    /**
     * Fecha equilibrada para un repaso con intervalo SM-2 {@code intervalDays} que vencería en {@code proposed}.
     * Conserva la hora; solo cambia el día.
     */
    public static Instant balance(Instant proposed, int intervalDays, Load load) {
        if (load == null || load.perDay().isEmpty()) {
            return proposed;
        }
        LocalDate day = LocalDate.ofInstant(proposed, load.zone());
        int bestShift = 0;
        int bestCount = load.on(day);
        for (int distance = 1; distance <= Math.max(maxAdvance(intervalDays), maxDelay(intervalDays)); distance++) {
            // Primero el anterior: con empate a la misma distancia gana repasar antes.
            for (int shift : new int[] {-distance, distance}) {
                boolean allowed = shift < 0 ? -shift <= maxAdvance(intervalDays) : shift <= maxDelay(intervalDays);
                if (allowed && load.on(day.plusDays(shift)) < bestCount) {
                    bestShift = shift;
                    bestCount = load.on(day.plusDays(shift));
                }
            }
        }
        return proposed.plus(bestShift, ChronoUnit.DAYS);
    }
}
