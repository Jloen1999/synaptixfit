package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.ReviewRecord;
import com.synaptixfit.domain.port.output.academic.ReviewRecordRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.ReviewRecordJpaRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link ReviewRecordRepositoryPort} con JPA. */
@Repository
public class ReviewRecordPersistenceAdapter implements ReviewRecordRepositoryPort {

    private final ReviewRecordJpaRepository repository;

    public ReviewRecordPersistenceAdapter(ReviewRecordJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public ReviewRecord save(ReviewRecord record) {
        // Se vuelca al momento: indicadores leen registros_repaso_srs con JDBC en la misma transacción.
        return AcademicPersistenceMapper.toDomain(repository.saveAndFlush(AcademicPersistenceMapper.toEntity(record)));
    }

    @Override
    public List<ReviewRecord> findByMaterial(UUID studyMaterialId) {
        return repository.findByStudyMaterialIdOrderByReviewedAtDesc(studyMaterialId).stream()
                .map(AcademicPersistenceMapper::toDomain).toList();
    }
}
