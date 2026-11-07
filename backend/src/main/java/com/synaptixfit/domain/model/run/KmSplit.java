package com.synaptixfit.domain.model.run;

/**
 * Un tramo del análisis por kilómetro: el número de kilómetro, los metros (1000, o menos en el último, incompleto)
 * y los segundos en movimiento que costó. El ritmo es por km aunque el tramo sea más corto.
 */
public record KmSplit(int number, int distanceMeters, int seconds) {

    public int paceSecondsPerKm() {
        return distanceMeters <= 0 ? 0 : (int) Math.round(seconds * 1000.0 / distanceMeters);
    }
}
