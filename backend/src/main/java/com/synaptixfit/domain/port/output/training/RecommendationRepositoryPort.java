package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.Recommendation;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de las sugerencias de entrenamiento pendientes. */
public interface RecommendationRepositoryPort {

    Recommendation save(Recommendation recommendation);

    void saveAll(List<Recommendation> recommendations);

    Optional<Recommendation> findById(UUID id);

    /** Más recientes primero; {@code applied} nulo no filtra. */
    PageResult<Recommendation> findByUser(UUID userId, Boolean applied, PageRequest page);

    void delete(UUID id);
}
