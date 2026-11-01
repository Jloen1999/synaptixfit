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
                       Instant end, boolean allDay, String categories) {

    private static final List<String> EXAM_KEYWORDS =
            List.of("examen", "parcial", "quiz", "cuestionario", "evaluacion", "test", "final", "midterm", "exam");
    /** Avisos de apertura de Moodle («El cuestionario X se abre»): no son una fecha que cumplir. */
    private static final List<String> OPENING_KEYWORDS = List.of(" se abre", " abre", " opens", " is open");
    private static final List<String> DELIVERY_KEYWORDS =
            List.of("entrega", "tarea", "proyecto", "deadline", "trabajo", "assignment", "submission");

    /** Sin categorías (calendarios que no las traen). */
    public IcsEvent(String uid, String summary, String description, String location, Instant start, Instant end,
                    boolean allDay) {
        this(uid, summary, description, location, start, end, allDay, null);
    }

    /** Clasificación heredada por palabras clave del título. */
    public enum Category {
        EXAM,
        DELIVERY,
        CLASS
    }

    /** Festivos y avisos de que no hay clase: no son algo que hacer ni una clase. */
    private static final List<String> NON_TEACHING_KEYWORDS =
            List.of("festivo", "fiesta", "no hay clase", "no lectivo", "vacaciones", "puente");

    /** ¿Es un festivo o un aviso de que no hay clase? */
    public boolean isNonTeaching() {
        String text = " " + SubjectMatcher.normalize(summary) + " ";
        return NON_TEACHING_KEYWORDS.stream().anyMatch(k -> text.contains(" " + k + " ") || text.contains(" " + k));
    }

    /** ¿Es solo el aviso de que algo se abre (no una fecha límite)? */
    public boolean isOpeningNotice() {
        String text = " " + SubjectMatcher.normalize(summary);
        return OPENING_KEYWORDS.stream().anyMatch(text::endsWith) || text.contains(" se abre ");
    }

    /**
     * Textos donde buscar la asignatura, por orden de fiabilidad: título y categorías (Moodle pone el curso) y,
     * como último recurso, la descripción, que puede mencionar otras asignaturas.
     */
    public List<String> subjectHints() {
        String main = String.join(" ", summary == null ? "" : summary, categories == null ? "" : categories);
        return List.of(main, description == null ? "" : description);
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
