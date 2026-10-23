package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Auditoría inmutable de un repaso SM-2-Physio: calidad declarada, calidad ajustada por fatiga
 * y coeficiente de fatiga aplicado ({@code eta * carga_hoy / carga_max}).
 */
public record ReviewRecord(UUID id, UUID studyMaterialId, Instant reviewedAt, int realQuality,
                           double adjustedQuality, double fatigueCoefficient) {

    public ReviewRecord {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(studyMaterialId, "studyMaterialId");
        Objects.requireNonNull(reviewedAt, "reviewedAt");
        Guard.range(realQuality, "quality", 0, 5);
    }
}
