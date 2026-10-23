package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.ExerciseAdjustment;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.Recommendation;
import com.synaptixfit.domain.model.training.RecommendationType;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.TrainingSession;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Motor de feedback: tras una sesión propone ajustes concretos para la próxima.
 *
 * <ul>
 *   <li>Repeticiones fallidas o RPE ≥ 9,5 → {@code DEGRADATION} con la carga reducida.</li>
 *   <li>Sin fallos, todas las series completadas y RPE ≤ 7 → {@code PROGRESSION} (+repeticiones o
 *       +carga según la doble progresión).</li>
 *   <li>Más de 14 días sin entrenar al empezar una sesión → {@code DELOAD} al 80 % / 70 %.</li>
 * </ul>
 * A diferencia del sistema heredado, cada sugerencia lleva los parámetros nuevos por ejercicio, de
 * modo que aplicarla los copia a la rutina.
 */
public final class SessionFeedback {

    private SessionFeedback() {
    }

    public static List<Recommendation> afterSession(TrainingSession session, Map<UUID, PlannedExercise> planned,
                                                    GoalParameters goal, Instant now) {
        if (!session.isCompleted() || session.rpe() == null || session.sets().isEmpty()) {
            return List.of();
        }
        Map<UUID, List<SessionSet>> byPlanned = new LinkedHashMap<>();
        for (SessionSet s : session.sets()) {
            if (s.plannedExerciseId() != null && planned.containsKey(s.plannedExerciseId())) {
                byPlanned.computeIfAbsent(s.plannedExerciseId(), k -> new ArrayList<>()).add(s);
            }
        }
        int totalSets = session.sets().size();
        int completedSets = (int) session.sets().stream().filter(SessionSet::completed).count();
        int totalFailed = session.sets().stream().mapToInt(SessionSet::failedReps).sum();
        int rpe = session.rpe();

        List<ExerciseAdjustment> adjustments = new ArrayList<>();
        byPlanned.forEach((plannedId, sets) -> {
            PlannedExercise p = planned.get(plannedId);
            ProgressionCalculator.Result r = ProgressionCalculator.progress(p.parameters(),
                    p.exercise().measurementTypes(), rpe, sets, goal);
            if (r.changed(p.parameters())) {
                adjustments.add(new ExerciseAdjustment(plannedId, p.exerciseId(), p.exercise().name(),
                        r.parameters(), r.log()));
            }
        });
        if (adjustments.isEmpty()) {
            return List.of();
        }
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("sessionId", session.id().toString());
        details.put("rpe", rpe);
        details.put("totalSets", totalSets);
        details.put("completedSets", completedSets);
        details.put("totalFailedReps", totalFailed);

        if (totalFailed > 0 || rpe >= 9.5) {
            int reduction = totalFailed > 0 ? 100 - Math.max(70, Math.min(95, 100 - totalFailed * 5)) : 15;
            String title = totalFailed > 0
                    ? "Reducir carga: " + totalFailed + " repeticiones fallidas"
                    : "Reducir carga: sesión muy exigente";
            String description = totalFailed > 0
                    ? "Fallaste repeticiones en " + (totalSets - completedSets) + " de " + totalSets
                      + " series. Para la próxima sesión se recomienda bajar la carga un " + reduction + " %."
                    : "Marcaste un esfuerzo máximo (RPE " + rpe + "). Baja la carga un 15 % la próxima vez.";
            return List.of(Recommendation.create(session.userId(), RecommendationType.DEGRADATION, title,
                    description, session.routineId(), adjustments, details, now));
        }
        if (rpe <= 7 && completedSets == totalSets) {
            return List.of(Recommendation.create(session.userId(), RecommendationType.PROGRESSION,
                    "Considera aumentar la carga",
                    "Completaste todas las series sin fallos con RPE " + rpe
                            + ". Aplica la progresión para la próxima sesión.",
                    session.routineId(), adjustments, details, now));
        }
        return List.of();
    }

    public static Optional<Recommendation> afterInactivity(UUID userId, UUID routineId, int daysInactive,
                                                           List<PlannedExercise> dayExercises, GoalParameters goal,
                                                           Instant now) {
        if (daysInactive <= ProgressionCalculator.INACTIVITY_DAYS) {
            return Optional.empty();
        }
        List<ExerciseAdjustment> adjustments = new ArrayList<>();
        for (PlannedExercise p : dayExercises) {
            ProgressionCalculator.Result r = ProgressionCalculator.degradeForInactivity(p.parameters(),
                    p.exercise().measurementTypes(), daysInactive, goal);
            if (r.changed(p.parameters())) {
                adjustments.add(new ExerciseAdjustment(p.id(), p.exerciseId(), p.exercise().name(), r.parameters(),
                        r.log()));
            }
        }
        double factor = daysInactive > 21 ? 0.70 : 0.80;
        return Optional.of(Recommendation.create(userId, RecommendationType.DELOAD,
                "Volviste después de " + daysInactive + " días",
                "Retoma con el " + Math.round(factor * 100) + " % de tu carga habitual para evitar agujetas severas.",
                routineId, adjustments, Map.of("daysInactive", daysInactive, "loadFactor", factor), now));
    }
}
