package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;
import java.text.Normalizer;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * Buscador único de Académico (ADR 0036): asignaturas, apuntes, archivos y entregas o exámenes, agrupados por tipo.
 *
 * <p>Reglas: el texto se recorta y debe tener entre {@link #MIN_LENGTH} y {@link #MAX_LENGTH} caracteres; la búsqueda no
 * distingue mayúsculas ni tildes («fisica» encuentra «Física»), y cada grupo trae como mucho {@link #PER_GROUP}
 * resultados y si hay más.
 */
public final class AcademicSearch {

    public static final int MIN_LENGTH = 2;
    public static final int MAX_LENGTH = 100;
    public static final int PER_GROUP = 5;

    private AcademicSearch() {
    }

    /** Tipo de resultado, en el orden en que se enseñan los grupos. */
    public enum Kind { SUBJECT, NOTE, FILE, DEADLINE }

    /**
     * Resultado. {@code context}: lo que ayuda a reconocerlo (la asignatura de un apunte, un archivo o una entrega; las
     * siglas de una asignatura). {@code at}: la fecha de una entrega. {@code exam}: si la entrega es un examen.
     */
    public record Hit(Kind kind, UUID id, String title, String context, UUID subjectId, Instant at, boolean exam) {
    }

    /** Resultados de un tipo; {@code more}: hay más de los que se enseñan. */
    public record Group(Kind kind, List<Hit> hits, boolean more) {

        public Group {
            hits = List.copyOf(hits);
        }

        /** Recorta a {@link #PER_GROUP}: el puerto trae uno más para saber si hay más. */
        public static Group of(Kind kind, List<Hit> found) {
            return new Group(kind, found.stream().limit(PER_GROUP).toList(), found.size() > PER_GROUP);
        }
    }

    /** Resultados por grupos, solo los grupos con algo. */
    public record Result(String query, List<Group> groups) {

        public Result {
            groups = groups.stream().filter(g -> !g.hits().isEmpty()).toList();
        }

        public boolean isEmpty() {
            return groups.isEmpty();
        }
    }

    /** Texto buscado ya validado y su forma plegada (minúsculas, sin tildes) con la que se compara. */
    public record Query(String text, String folded) {

        public static Query of(String raw) {
            String text = Guard.length(raw == null ? null : raw.strip().replaceAll("\\s+", " "), "q", MIN_LENGTH,
                    MAX_LENGTH);
            return new Query(text, fold(text));
        }
    }

    /** Minúsculas y sin tildes ni diéresis: la misma forma con la que el adaptador compara las columnas. */
    public static String fold(String text) {
        String decomposed = Normalizer.normalize(text.toLowerCase(Locale.ROOT), Normalizer.Form.NFD);
        return decomposed.replaceAll("\\p{M}+", "");
    }
}
