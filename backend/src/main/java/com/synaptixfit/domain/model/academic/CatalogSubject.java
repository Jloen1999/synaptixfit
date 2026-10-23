package com.synaptixfit.domain.model.academic;

import java.util.UUID;

/**
 * Asignatura del catálogo académico (plan de estudios), de solo lectura para este módulo.
 * {@code code} es el código oficial de la universidad (p. ej. 502376), si se conoce.
 */
public record CatalogSubject(UUID id, UUID degreeId, String name, Integer course, Integer semester,
                             String character, Double credits, Integer hours, String guideUrl, String code) {

    /** Es la asignatura de un plan docente si coincide el código oficial o el nombre. */
    public boolean matches(TeachingGuide.SubjectInfo info) {
        return info != null && info.matches(name, code);
    }

    /** Créditos enteros válidos para una asignatura del usuario (1-30); si no, el valor por defecto. */
    public int creditsForSubject() {
        if (credits == null) {
            return Subject.DEFAULT_CREDITS;
        }
        long rounded = Math.round(credits);
        return rounded < 1 || rounded > 30 ? Subject.DEFAULT_CREDITS : (int) rounded;
    }

    /** Descripción breve («Curso 2 · Sem 1 · Obligatoria · 6.0 ECTS») como la del selector antiguo. */
    public String describe() {
        StringBuilder sb = new StringBuilder();
        append(sb, course == null ? null : "Curso " + course);
        append(sb, semester == null ? null : "Sem " + semester);
        append(sb, character);
        append(sb, credits == null ? null : credits + " ECTS");
        return sb.isEmpty() ? null : sb.toString();
    }

    private static void append(StringBuilder sb, String part) {
        if (part == null || part.isBlank()) {
            return;
        }
        if (!sb.isEmpty()) {
            sb.append(" · ");
        }
        sb.append(part);
    }
}
