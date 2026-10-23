package com.synaptixfit.domain.model.planner;

import java.time.Instant;
import java.util.List;
import java.util.Locale;

/**
 * Evento leído de un calendario ICS (VEVENT).
 *
 * @param allDay evento de día completo ({@code VALUE=DATE}); su inicio se fija a las 09:00 locales
 */
public record IcsEvent(String uid, String summary, String description, String location, Instant start,
                       Instant end, boolean allDay) {

    private static final List<String> EXAM_KEYWORDS =
            List.of("examen", "parcial", "quiz", "evaluacion", "test", "final", "midterm", "exam");
    private static final List<String> DELIVERY_KEYWORDS =
            List.of("entrega", "tarea", "proyecto", "deadline", "trabajo", "assignment", "submission");

    /** Clasificación heredada por palabras clave del título. */
    public enum Category {
        EXAM,
        DELIVERY,
        CLASS
    }

    public Category category() {
        String text = SubjectMatcher.normalize(summary).toLowerCase(Locale.ROOT);
        if (EXAM_KEYWORDS.stream().anyMatch(text::contains)) {
            return Category.EXAM;
        }
        if (DELIVERY_KEYWORDS.stream().anyMatch(text::contains)) {
            return Category.DELIVERY;
        }
        return Category.CLASS;
    }
}
