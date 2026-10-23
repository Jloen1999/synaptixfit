package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.WeightRecord;
import java.time.Instant;
import java.util.UUID;

/** Punto del historial de peso. */
public record WeightRecordResponse(UUID id, double weightKg, double heightCm, double bmi, Instant recordedAt) {

    public static WeightRecordResponse from(WeightRecord r) {
        return new WeightRecordResponse(r.id(), r.weightKg(), r.heightCm(), r.bmi(), r.recordedAt());
    }
}
