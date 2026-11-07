package com.synaptixfit.domain.model.academic;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.TreeSet;

/**
 * Lo próximo y accionable de una asignatura (ADR 0036): su próxima clase con el aula, los días de clase y su próxima
 * entrega o examen sin hacer. Lo pinta la tarjeta de Académico («Próxima clase: lun 10:00 · Aula 2.3», «Entrega en 3
 * días») y el detalle («Clase los lunes y miércoles»).
 *
 * @param nextClassAt    inicio de la próxima clase, o {@code null}
 * @param nextClassPlace aula de esa clase o, si el horario no la trae, el aula habitual de la asignatura
 * @param classDays      días de la semana con clase en las próximas {@link #CLASS_DAYS_WINDOW_DAYS} (1 = lunes)
 * @param nextDeadline   próxima entrega o examen sin hacer, o {@code null}
 */
public record SubjectAgenda(Instant nextClassAt, String nextClassPlace, List<Integer> classDays,
                            Deadline nextDeadline) {

    /** Dos semanas: cubre un horario semanal y el de semanas alternas. */
    public static final int CLASS_DAYS_WINDOW_DAYS = 14;

    public static final SubjectAgenda EMPTY = new SubjectAgenda(null, null, List.of(), null);

    public SubjectAgenda {
        classDays = classDays == null ? List.of() : List.copyOf(classDays);
    }

    /** Clase del horario (bloque de tipo clase) con su aula, si la tiene. */
    public record ClassSlot(Instant start, String place) {
    }

    /** Entrega o examen pendiente de la asignatura. */
    public record Deadline(String title, Instant dueAt, boolean exam) {
    }

    /**
     * Junta las clases y entregas futuras de una asignatura. {@code classes} y {@code deadlines} llegan ya filtradas
     * (futuras, sin hacer, de esa asignatura); aquí se elige la más cercana y se sacan los días en la zona de la
     * persona.
     */
    public static SubjectAgenda of(List<ClassSlot> classes, List<Deadline> deadlines, String defaultRoom,
                                   ZoneId zone) {
        Optional<ClassSlot> next = classes.stream().min(Comparator.comparing(ClassSlot::start));
        Instant windowEnd = next.map(c -> c.start().plus(java.time.Duration.ofDays(CLASS_DAYS_WINDOW_DAYS)))
                .orElse(null);
        TreeSet<Integer> days = new TreeSet<>();
        for (ClassSlot c : classes) {
            if (windowEnd != null && c.start().isBefore(windowEnd)) {
                DayOfWeek day = c.start().atZone(zone).getDayOfWeek();
                days.add(day.getValue());
            }
        }
        String place = next.map(ClassSlot::place).filter(p -> p != null && !p.isBlank()).orElse(defaultRoom);
        Deadline deadline = deadlines.stream().min(Comparator.comparing(Deadline::dueAt)).orElse(null);
        return new SubjectAgenda(next.map(ClassSlot::start).orElse(null), next.isPresent() ? place : null,
                List.copyOf(days), deadline);
    }
}
