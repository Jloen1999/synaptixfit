package com.synaptixfit.domain.model.run;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;

/**
 * Un paso de un entreno de carrera: «Calentar 10 min», «Correr 800 m», «Recuperar 2 min», «Enfriar 5 min». Se mide
 * en tiempo (segundos) o en distancia (metros).
 */
public record RunStep(Type type, Measure measure, int value) {

    /** Qué se hace en el paso. */
    public enum Type { WARMUP, RUN, RECOVER, COOLDOWN }

    /** Cómo se mide el paso. */
    public enum Measure { TIME, DISTANCE }

    public static final int MIN_SECONDS = 10;
    public static final int MAX_SECONDS = 3 * 3600;
    public static final int MIN_METERS = 50;
    public static final int MAX_METERS = 50_000;
    /** Ritmo de referencia (6 min/km) para estimar cuánto dura un paso de distancia al ponerlo en el calendario. */
    public static final int REFERENCE_PACE_SECONDS_PER_KM = 360;

    public RunStep {
        Guard.notNull(type, "type");
        Guard.notNull(measure, "measure");
        if (measure == Measure.TIME) {
            Guard.range(value, "value", MIN_SECONDS, MAX_SECONDS);
        } else if (value < MIN_METERS || value > MAX_METERS) {
            throw new FieldValidationException("value", "OUT_OF_RANGE",
                    "distance must be between " + MIN_METERS + " and " + MAX_METERS + " m");
        }
    }

    public static RunStep time(Type type, int seconds) {
        return new RunStep(type, Measure.TIME, seconds);
    }

    public static RunStep distance(Type type, int meters) {
        return new RunStep(type, Measure.DISTANCE, meters);
    }

    /** Segundos previstos: los del paso o, si es de distancia, al ritmo de referencia. */
    public int estimatedSeconds() {
        return measure == Measure.TIME ? value : (int) Math.round(value / 1000.0 * REFERENCE_PACE_SECONDS_PER_KM);
    }
}
