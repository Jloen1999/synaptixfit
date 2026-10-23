package com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.ReviewRecordEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code registros_repaso_srs}. */
public interface ReviewRecordJpaRepository extends JpaRepository<ReviewRecordEntity, UUID> {

    List<ReviewRecordEntity> findByStudyMaterialIdOrderByReviewedAtDesc(UUID studyMaterialId);
}
