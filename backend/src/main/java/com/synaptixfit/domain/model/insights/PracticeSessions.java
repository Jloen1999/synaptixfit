package com.synaptixfit.domain.model.insights;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Qué prácticas sin bloque (Pomodoro, tests y repasos SM-2) cuentan como actividad académica sin contar
 * dos veces lo que ya cuenta un bloque completado del calendario. Antes eran condiciones
 * {@code NOT EXISTS} dentro del SQL; ahora el adaptador trae las filas ({@link Log}) y los casos de uso
 * aplican estas reglas con {@link #countable(Log)}.
 */
public final class PracticeSessions {

    private PracticeSessions() {
    }

    /** Fase Pomodoro completada; {@code insideCompletedBlock}: se hizo en un bloque que acabó completado. */
    public record Focus(UUID id, Instant completedAt, int minutes, Integer perceivedDifficulty,
                        boolean insideCompletedBlock) {
    }

    /** Test de práctica terminado. */
    public record TestSession(UUID id, Instant startedAt, Instant completedAt, Integer perceivedDifficulty) {
    }

    /** Repaso SM-2 de un material. */
    public record Review(UUID id, Instant at, UUID materialId, Integer perceivedDifficulty) {
    }

    /**
     * Filas de práctica de un periodo tal como están guardadas, más los materiales con un bloque de
     * repaso completado en ese periodo.
     */
    public record Log(List<Focus> focus, List<TestSession> tests, List<Review> reviews,
                      Set<UUID> materialsWithCompletedBlock) {

        public Log {
            focus = List.copyOf(focus);
            tests = List.copyOf(tests);
            reviews = List.copyOf(reviews);
            materialsWithCompletedBlock = Set.copyOf(materialsWithCompletedBlock);
        }

        public static Log empty() {
            return new Log(List.of(), List.of(), List.of(), Set.of());
        }
    }

    /** Prácticas que cuentan, expresadas como actividad académica (Pomodoro = estudio; test y repaso = repaso). */
    public static List<CompletedStudyBlock> countable(Log log) {
        List<CompletedStudyBlock> result = new ArrayList<>();
        for (Focus f : log.focus()) {
            if (focusCounts(f.insideCompletedBlock())) {
                result.add(CompletedStudyBlock.focus(f.id(), f.completedAt(), f.minutes(), f.perceivedDifficulty()));
            }
        }
        for (TestSession t : log.tests()) {
            result.add(CompletedStudyBlock.test(t.id(), t.startedAt(), t.completedAt(), t.perceivedDifficulty()));
        }
        for (Review r : log.reviews()) {
            if (reviewCounts(r.materialId(), log.materialsWithCompletedBlock())) {
                result.add(CompletedStudyBlock.review(r.id(), r.at(), r.perceivedDifficulty()));
            }
        }
        return result;
    }

    /** Un Pomodoro hecho dentro de un bloque que acabó completado ya está imputado en ese bloque. */
    public static boolean focusCounts(boolean insideCompletedBlock) {
        return !insideCompletedBlock;
    }

    /**
     * Un repaso SM-2 no cuenta si su material tiene un bloque de repaso completado en el mismo
     * periodo: el bloque ya imputa ese tiempo de estudio.
     */
    public static boolean reviewCounts(UUID materialId, Set<UUID> materialsWithCompletedBlock) {
        return !materialsWithCompletedBlock.contains(materialId);
    }
}
