package com.synaptixfit.domain.model.training.load;

import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.TrackingKind;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import java.time.Instant;
import java.util.List;

/**
 * Calibración del peso en la primera sesión de un ejercicio (ADR 0054, {@code formulas.md}). Tras la primera serie
 * de trabajo se pregunta «¿Cuántas más podrías haber hecho?»:
 * <ul>
 *   <li>4 o más → la serie siguiente sube un escalón del material ({@link LoadStep#up});</li>
 *   <li>3 o 1-2 → se queda (3 es lo que se pide a quien empieza; 1-2 ya es zona de trabajo);</li>
 *   <li>0, o no llegó a las repeticiones previstas → baja un escalón.</li>
 * </ul>
 * El peso que queda pasa a la rutina en los días que aún no se han hecho; desde la segunda sesión manda la doble
 * progresión.
 */
public final class ExerciseCalibration {

    private ExerciseCalibration() {
    }

    /** Resultado: qué hacer y el peso de la serie siguiente (nulo si la serie no llevaba kilos). */
    public record Result(CalibrationStep step, Double nextWeightKg) {
    }

    /**
     * Se calibra un ejercicio de repeticiones con kilos que no se ha hecho con peso en los últimos
     * {@value StartingLoad#HISTORY_DAYS} días (con historial, el peso de partida ya sale de él). Con peso corporal o
     * gomas no hay kilos que ajustar.
     */
    public static boolean needed(ExerciseRef exercise, List<CompletedSessionSummary> recent, Instant now) {
        return exercise.measuredBy(MeasurementType.WEIGHT)
                && (exercise.load() == null || !exercise.load().type().unloaded())
                && exercise.trackingKind() == TrackingKind.REPETITIONS
                && !StartingLoad.doneWithWeight(recent, exercise.id(), now);
    }

    /**
     * Se acepta una respuesta tras la primera serie de trabajo de un ejercicio que se calibra ({@link #needed}), o para
     * cambiar la que ya se dio en esta sesión. Cualquier otra cambiaría el peso de la rutina saltándose la doble
     * progresión.
     */
    public static boolean accepts(int setNumber, boolean needed, boolean alreadyAnswered) {
        return alreadyAnswered || setNumber == 1 && needed;
    }

    /**
     * @param weightKg   peso de la serie que se acaba de hacer (nulo si no se apuntó)
     * @param repsMissed no llegó a las repeticiones previstas
     */
    public static Result adjust(CalibrationAnswer answer, Double weightKg, LoadProfile profile, boolean repsMissed) {
        CalibrationStep step = repsMissed || answer == CalibrationAnswer.NONE ? CalibrationStep.DOWN
                : answer == CalibrationAnswer.FOUR_PLUS ? CalibrationStep.UP : CalibrationStep.KEEP;
        if (profile != null && profile.type().unloaded()) {
            return new Result(CalibrationStep.KEEP, weightKg);
        }
        if (weightKg == null || weightKg <= 0) {
            return new Result(step, null);
        }
        double next = switch (step) {
            case UP -> LoadStep.up(weightKg, profile);
            case DOWN -> LoadStep.down(weightKg, profile);
            case KEEP -> weightKg;
        };
        // Ya en el mínimo (barra vacía, la pesa más ligera): no hay escalón al que bajar.
        return new Result(next == weightKg ? CalibrationStep.KEEP : step, next);
    }
}
