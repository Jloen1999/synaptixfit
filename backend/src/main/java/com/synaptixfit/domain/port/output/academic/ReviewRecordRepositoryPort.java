package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.ReviewRecord;
import java.util.List;
import java.util.UUID;

/** Auditoría de repasos SM-2 ({@code registros_repaso_srs}). */
public interface ReviewRecordRepositoryPort {

    ReviewRecord save(ReviewRecord record);

    /** Historial de repasos del material, el más reciente primero. */
    List<ReviewRecord> findByMaterial(UUID studyMaterialId);
}
