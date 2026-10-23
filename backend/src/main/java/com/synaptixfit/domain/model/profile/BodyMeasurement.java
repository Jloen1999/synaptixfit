package com.synaptixfit.domain.model.profile;

import com.synaptixfit.domain.model.shared.Guard;

/**
 * Peso y altura del usuario. El IMC siempre lo calcula el dominio (nunca lo envía el cliente) y
 * se redondea a un decimal.
 */
public record BodyMeasurement(double weightKg, double heightCm) {

    public static final double MIN_WEIGHT = 30;
    public static final double MAX_WEIGHT = 250;
    public static final double MIN_HEIGHT = 120;
    public static final double MAX_HEIGHT = 230;

    public BodyMeasurement {
        Guard.range(weightKg, "weightKg", MIN_WEIGHT, MAX_WEIGHT);
        Guard.range(heightCm, "heightCm", MIN_HEIGHT, MAX_HEIGHT);
    }

    /** IMC = peso (kg) / altura (m)². */
    public double bmi() {
        double meters = heightCm / 100.0;
        return Math.round(weightKg / (meters * meters) * 10.0) / 10.0;
    }
}
