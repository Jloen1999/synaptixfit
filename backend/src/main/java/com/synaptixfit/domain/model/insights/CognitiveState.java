package com.synaptixfit.domain.model.insights;

import com.synaptixfit.domain.model.neuro.CognitiveLoad;
import com.synaptixfit.domain.model.neuro.StudyBlockLoad;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Estado cognitivo del usuario (fila 1:1 de {@code estado_cognitivo_usuario}).
 *
 * <p>Se recalcula siempre desde cero con los bloques completados de hoy (fórmula 2), en lugar de
 * sumar y restar incrementos como hacía la app antigua: así marcar/desmarcar es reversible sin
 * deriva y la carga se reinicia cada día.
 * <ul>
 *   <li>Carga: {@link CognitiveLoad#accumulated} con el descanso real entre bloques consecutivos.</li>
 *   <li>Capacidad atencional: {@code A(t)} con {@code A0 = 1} y {@code t} = minutos de la racha de
 *       trabajo continuo más reciente (bloques separados por menos de {@value #REST_GAP_MINUTES} min).</li>
 *   <li>Último descanso: inicio de esa racha (momento en que terminó el último descanso).</li>
 * </ul>
 */
public final class CognitiveState {

    /**
     * Pausa mínima (minutos) que se considera descanso y corta la racha de trabajo continuo: los 17 min
     * del ciclo 52/17 de DeskTime (ver {@link com.synaptixfit.domain.model.neuro.CognitiveLoad}).
     */
    public static final int REST_GAP_MINUTES = 17;

    private final UUID userId;
    private final Instant createdAt;
    private double cognitiveLoad;
    private double attentionCapacity;
    private int lastBlockMinutes;
    private Instant lastRestAt;
    private Double rmrBase;
    private Instant updatedAt;

    public CognitiveState(UUID userId, double cognitiveLoad, double attentionCapacity, int lastBlockMinutes,
                          Instant lastRestAt, Double rmrBase, Instant createdAt, Instant updatedAt) {
        this.userId = Guard.notNull(userId, "userId");
        this.cognitiveLoad = Guard.range(cognitiveLoad, "cognitiveLoad", 0, 1);
        this.attentionCapacity = Guard.range(attentionCapacity, "attentionCapacity", 0, 1);
        this.lastBlockMinutes = Math.max(0, lastBlockMinutes);
        this.lastRestAt = lastRestAt;
        this.rmrBase = rmrBase;
        this.createdAt = Guard.notNull(createdAt, "createdAt");
        this.updatedAt = Guard.notNull(updatedAt, "updatedAt");
    }

    public static CognitiveState initial(UUID userId, Instant now) {
        return new CognitiveState(userId, 0, 1, 0, null, null, now, now);
    }

    /**
     * Recalcula el estado con los bloques cognitivos completados de hoy.
     *
     * @param rmr tasa metabólica en reposo actual (null si el perfil no la permite; se conserva la anterior)
     */
    public void recompute(List<CompletedStudyBlock> todayBlocks, Double rmr, Instant now) {
        List<CompletedStudyBlock> blocks = new ArrayList<>(todayBlocks.stream()
                .filter(b -> CompletedStudyBlock.isCognitive(b.activityType()))
                .toList());
        blocks.sort(Comparator.comparing(CompletedStudyBlock::start));

        List<StudyBlockLoad> loads = new ArrayList<>();
        Instant previousEnd = null;
        Instant streakStart = null;
        double streakMinutes = 0;
        for (CompletedStudyBlock b : blocks) {
            double rest = previousEnd == null ? 0 : Math.max(0, minutesBetween(previousEnd, b.start()));
            loads.add(new StudyBlockLoad(b.durationMinutes(),
                    CognitiveLoad.difficultyMultiplier(b.perceivedDifficulty() == null ? 1 : b.perceivedDifficulty()),
                    rest));
            if (previousEnd == null || rest >= REST_GAP_MINUTES) {
                streakStart = b.start();
                streakMinutes = 0;
            }
            streakMinutes += b.durationMinutes();
            if (previousEnd == null || b.end().isAfter(previousEnd)) {
                previousEnd = b.end();
            }
        }

        this.cognitiveLoad = CognitiveLoad.accumulated(loads);
        this.attentionCapacity = Math.max(0, Math.min(1, CognitiveLoad.attentionCapacity(1.0, (int) Math.round(streakMinutes))));
        this.lastBlockMinutes = blocks.isEmpty() ? 0 : (int) Math.round(blocks.stream()
                .max(Comparator.comparing(CompletedStudyBlock::end)).orElseThrow().durationMinutes());
        if (streakStart != null) {
            this.lastRestAt = streakStart;
        }
        if (rmr != null) {
            this.rmrBase = rmr;
        }
        this.updatedAt = now;
    }

    private static double minutesBetween(Instant from, Instant to) {
        return Duration.between(from, to).getSeconds() / 60.0;
    }

    public UUID userId() { return userId; }
    public double cognitiveLoad() { return cognitiveLoad; }
    public double attentionCapacity() { return attentionCapacity; }
    public int lastBlockMinutes() { return lastBlockMinutes; }
    public Instant lastRestAt() { return lastRestAt; }
    public Double rmrBase() { return rmrBase; }
    public Instant createdAt() { return createdAt; }
    public Instant updatedAt() { return updatedAt; }
}
