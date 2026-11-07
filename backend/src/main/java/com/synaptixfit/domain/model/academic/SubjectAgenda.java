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
 * @param nextUp         lo que la tarjeta destaca ({@link NextUp}), o {@code null} si no hay nada
 */
public record SubjectAgenda(Instant nextClassAt, String nextClassPlace, List<Integer> classDays,
                            Deadline nextDeadline, NextUp nextUp) {

    /** Dos semanas: cubre un horario semanal y el de semanas alternas. */
    public static final int CLASS_DAYS_WINDOW_DAYS = 14;

    /** Lo que vence hoy o mañana es urgente: la tarjeta lo destaca con el color de aviso. */
    public static final int URGENT_DAYS = 1;

    public static final SubjectAgenda EMPTY = new SubjectAgenda(null, null, List.of(), null, null);

    public SubjectAgenda {
        classDays = classDays == null ? List.of() : List.copyOf(classDays);
    }

    /** Clase del horario (bloque de tipo clase) con su aula, si la tiene. */
    public record ClassSlot(Instant start, String place) {
    }

    /** Entrega o examen pendiente de la asignatura. */
    public record Deadline(String title, Instant dueAt, boolean exam) {
    }

    /** Qué es lo próximo que destaca la tarjeta. */
    public enum NextUpKind { DELIVERY, EXAM, CLASS, ASSESSMENT }

    /**
     * Lo próximo de la asignatura tal como lo pinta la tarjeta: qué es, cuándo, dónde (solo clases), cuántos días
     * naturales faltan en la zona de la persona y si urge (hoy o mañana).
     */
    public record NextUp(NextUpKind kind, Instant at, String place, int daysLeft, boolean urgent) {
    }

    /**
     * Junta las clases y entregas futuras de una asignatura. {@code classes} y {@code deadlines} llegan ya filtradas
     * (futuras, sin hacer, de esa asignatura); aquí se elige la más cercana y se sacan los días en la zona de la
     * persona.
     */
    public static SubjectAgenda of(List<ClassSlot> classes, List<Deadline> deadlines, String defaultRoom,
                                   ZoneId zone) {
        return of(classes, deadlines, defaultRoom, null, null, zone);
    }

    /**
     * Igual, eligiendo además lo que destaca la tarjeta ({@link #nextUp}) respecto a {@code now}; la fecha de
     * evaluación de la asignatura ({@code nextAssessmentAt}) sirve si no hay nada más.
     */
    public static SubjectAgenda of(List<ClassSlot> classes, List<Deadline> deadlines, String defaultRoom,
                                   Instant nextAssessmentAt, Instant now, ZoneId zone) {
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
        Instant classAt = next.map(ClassSlot::start).orElse(null);
        String classPlace = next.isPresent() ? place : null;
        return new SubjectAgenda(classAt, classPlace, List.copyOf(days), deadline,
                now == null ? null : nextUp(classAt, classPlace, deadline, nextAssessmentAt, now, zone));
    }

    /**
     * Lo urgente primero: una entrega o examen de hoy o mañana gana a la clase; si no, la próxima clase; si no hay
     * clase, la entrega más cercana; y, sin nada de eso, la fecha de evaluación de la asignatura. Lo ya pasado no se
     * destaca.
     */
    static NextUp nextUp(Instant classAt, String classPlace, Deadline deadline, Instant assessmentAt, Instant now,
                         ZoneId zone) {
        Integer deadlineDays = deadline == null ? null : daysBetween(now, deadline.dueAt(), zone);
        if (deadlineDays != null && deadlineDays >= 0 && deadlineDays <= URGENT_DAYS) {
            return deadlineUp(deadline, deadlineDays);
        }
        if (classAt != null && classAt.isAfter(now)) {
            return new NextUp(NextUpKind.CLASS, classAt, classPlace, daysBetween(now, classAt, zone), false);
        }
        if (deadlineDays != null && deadlineDays >= 0) {
            return deadlineUp(deadline, deadlineDays);
        }
        if (assessmentAt == null) {
            return null;
        }
        int days = daysBetween(now, assessmentAt, zone);
        return days < 0 ? null
                : new NextUp(NextUpKind.ASSESSMENT, assessmentAt, null, days, days <= URGENT_DAYS);
    }

    private static NextUp deadlineUp(Deadline d, int days) {
        return new NextUp(d.exam() ? NextUpKind.EXAM : NextUpKind.DELIVERY, d.dueAt(), null, days,
                days <= URGENT_DAYS);
    }

    /** Días naturales de {@code from} a {@code to} en la zona de la persona (negativo si ya pasó). */
    private static int daysBetween(Instant from, Instant to, ZoneId zone) {
        return (int) java.time.temporal.ChronoUnit.DAYS.between(from.atZone(zone).toLocalDate(),
                to.atZone(zone).toLocalDate());
    }
}
