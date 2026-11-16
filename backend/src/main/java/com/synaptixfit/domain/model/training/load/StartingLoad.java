package com.synaptixfit.domain.model.training.load;

import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Peso de partida que se propone «para probar» en un ejercicio nuevo (ADR 0054, {@code formulas.md}). Cadena de
 * prioridades:
 * <ol>
 *   <li>Tu historial con ese ejercicio en los últimos {@value #HISTORY_DAYS} días: el peso de trabajo más alto de la
 *       última sesión con series de {@value #HISTORY_MAX_REPS} repeticiones o menos. Es lo más fiable y no se
 *       recorta.</li>
 *   <li>En máquinas, poleas, peso corporal y gomas no hay kilos de partida: manda la calibración.</li>
 *   <li>Quien ya entrena (nivel intermedio) sin historial: tampoco; la calibración lo ajusta.</li>
 *   <li>Fracción del peso corporal, conservadora a propósito (≈ 50-60 % de lo que suele poder un principiante),
 *       solo si se puede usar el peso del perfil (consentimiento de salud vigente).</li>
 *   <li>Si no, el peso fijo por defecto.</li>
 * </ol>
 * Las estimaciones se redondean hacia abajo al material ({@link LoadStep#floor}) y nunca pasan del tope del primer
 * día. La calibración de la primera sesión las corrige.
 */
public final class StartingLoad {

    public static final int HISTORY_DAYS = 42;
    public static final int HISTORY_MAX_REPS = 12;

    private StartingLoad() {
    }

    /**
     * @param historyKg    peso de tu historial ({@link #historyKg}); nulo si no hay
     * @param bodyWeightKg peso del perfil, solo si se puede usar; nulo si no
     * @return kilos de partida o nulo si no se propone ninguno
     */
    public static Double forExercise(LoadProfile profile, Double historyKg, Double bodyWeightKg,
                                     TemplateLevel level) {
        if (historyKg != null && historyKg > 0) {
            return historyKg;
        }
        if (profile == null || profile.type().machine() || profile.type().unloaded()
                || level == TemplateLevel.INTERMEDIATE) {
            return null;
        }
        Double estimate = bodyWeightKg != null && bodyWeightKg > 0 && profile.bodyWeightFraction() != null
                ? bodyWeightKg * profile.bodyWeightFraction() : profile.defaultKg();
        if (estimate == null || estimate <= 0) {
            return null;
        }
        double capped = profile.capKg() == null ? estimate : Math.min(estimate, profile.capKg());
        return LoadStep.floor(capped, profile);
    }

    /**
     * Peso de trabajo más alto de la sesión más reciente de los últimos {@value #HISTORY_DAYS} días con series del
     * ejercicio de {@value #HISTORY_MAX_REPS} repeticiones o menos. Nulo si no hay.
     *
     * @param recent sesiones completadas, las más recientes primero
     */
    public static Double historyKg(List<CompletedSessionSummary> recent, UUID exerciseId, Instant now) {
        for (CompletedSessionSummary session : recent) {
            if (tooOld(session, now)) {
                continue;
            }
            Double best = session.sets().stream()
                    .filter(p -> Objects.equals(p.exerciseId(), exerciseId))
                    .map(PerformedSet::set)
                    .filter(s -> s.weightKg() != null && s.weightKg() > 0 && s.repsDone() != null
                            && s.repsDone() > 0 && s.repsDone() <= HISTORY_MAX_REPS)
                    .map(s -> s.weightKg())
                    .max(Double::compare).orElse(null);
            if (best != null) {
                return best;
            }
        }
        return null;
    }

    /** ¿Hizo el ejercicio con kilos en los últimos {@value #HISTORY_DAYS} días? */
    public static boolean doneWithWeight(List<CompletedSessionSummary> recent, UUID exerciseId, Instant now) {
        return recent.stream().filter(s -> !tooOld(s, now))
                .flatMap(s -> s.sets().stream())
                .anyMatch(p -> Objects.equals(p.exerciseId(), exerciseId) && p.set().weightKg() != null
                        && p.set().weightKg() > 0);
    }

    private static boolean tooOld(CompletedSessionSummary session, Instant now) {
        return session.completedAt() == null
                || Duration.between(session.completedAt(), now).toDays() > HISTORY_DAYS;
    }
}
