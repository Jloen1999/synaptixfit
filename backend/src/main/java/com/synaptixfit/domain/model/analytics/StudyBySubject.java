package com.synaptixfit.domain.model.analytics;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Analítica de estudio por asignatura en las últimas semanas: horas (por semana) y cómo van los repasos.
 *
 * <p>«Recuerdas» es el porcentaje de repasos con calidad real (SM-2, 0-5) de 3 o más, el umbral que SM-2 usa para
 * dar el repaso por superado. Con al menos {@link #MIN_REVIEWS_FOR_VERDICT} repasos y menos de
 * {@link #WEAK_RECALL} se marca como floja: conviene repasarla más a menudo. Con menos repasos no se juzga.
 */
public record StudyBySubject(LocalDate firstWeek, int weeks, List<Subject> subjects) {

    public static final int PASSING_QUALITY = 3;
    public static final int MIN_REVIEWS_FOR_VERDICT = 3;
    public static final double WEAK_RECALL = 0.6;

    /**
     * @param minutesByWeek minutos de estudio de cada semana, de la más antigua a la actual
     * @param recallRate    repasos superados (0-1); null sin repasos
     * @param weak          pocos aciertos en los repasos: repasarla más a menudo
     */
    public record Subject(UUID subjectId, String name, int totalMinutes, List<Integer> minutesByWeek, int reviews,
                          Double recallRate, boolean weak) {
    }

    /** Bloque de estudio o repaso completado. */
    public record StudyBlock(UUID subjectId, Instant start, Instant end) {
    }

    /** Repaso hecho de un material de una asignatura. */
    public record Review(UUID subjectId, int quality) {
    }

    /**
     * Agrega por asignatura (las activas, aunque no tengan actividad, y lo hecho sin asignatura al final). Se
     * ordena por minutos de estudio.
     */
    public static StudyBySubject of(LocalDate firstWeek, int weeks, Map<UUID, String> subjectNames,
                                    List<StudyBlock> blocks, List<Review> reviews, ZoneId zone) {
        Map<UUID, int[]> minutes = new HashMap<>();
        for (StudyBlock b : blocks) {
            int week = (int) ChronoUnit.WEEKS.between(firstWeek, LocalDate.ofInstant(b.start(), zone));
            if (week < 0 || week >= weeks) {
                continue;
            }
            minutes.computeIfAbsent(b.subjectId(), k -> new int[weeks])[week] +=
                    (int) Duration.between(b.start(), b.end()).toMinutes();
        }
        Map<UUID, int[]> reviewCounts = new HashMap<>();
        for (Review r : reviews) {
            int[] counts = reviewCounts.computeIfAbsent(r.subjectId(), k -> new int[2]);
            counts[0]++;
            if (r.quality() >= PASSING_QUALITY) {
                counts[1]++;
            }
        }
        Map<UUID, String> names = new LinkedHashMap<>(subjectNames);
        minutes.keySet().forEach(id -> names.putIfAbsent(id, null));
        reviewCounts.keySet().forEach(id -> names.putIfAbsent(id, null));
        List<Subject> result = new ArrayList<>();
        for (Map.Entry<UUID, String> entry : names.entrySet()) {
            int[] byWeek = minutes.getOrDefault(entry.getKey(), new int[weeks]);
            int[] counts = reviewCounts.getOrDefault(entry.getKey(), new int[2]);
            Double recall = counts[0] == 0 ? null : (double) counts[1] / counts[0];
            boolean weak = counts[0] >= MIN_REVIEWS_FOR_VERDICT && recall < WEAK_RECALL;
            List<Integer> weekly = new ArrayList<>();
            int total = 0;
            for (int m : byWeek) {
                weekly.add(m);
                total += m;
            }
            result.add(new Subject(entry.getKey(), entry.getValue(), total, List.copyOf(weekly), counts[0], recall,
                    weak));
        }
        // Las asignaturas con actividad primero; lo hecho sin asignatura (id nulo), al final.
        result.sort(Comparator.comparing((Subject s) -> s.subjectId() == null)
                .thenComparing(Subject::totalMinutes, Comparator.reverseOrder())
                .thenComparing(Subject::reviews, Comparator.reverseOrder()));
        return new StudyBySubject(firstWeek, weeks, List.copyOf(result));
    }
}
