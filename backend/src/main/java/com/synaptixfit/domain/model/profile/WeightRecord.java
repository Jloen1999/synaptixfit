package com.synaptixfit.domain.model.profile;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/** Entrada del historial de peso (para las gráficas de evolución). */
public record WeightRecord(UUID id, UUID userId, double weightKg, double heightCm, double bmi, Instant recordedAt) {

    public WeightRecord {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(recordedAt, "recordedAt");
    }

    public static WeightRecord of(UUID userId, BodyMeasurement measurement, Instant when) {
        return new WeightRecord(UUID.randomUUID(), userId, measurement.weightKg(), measurement.heightCm(),
                measurement.bmi(), when);
    }
}
