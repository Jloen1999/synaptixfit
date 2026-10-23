package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.TeachingGuideImport;
import java.util.Optional;
import java.util.UUID;

/**
 * Persistencia de las importaciones de plan docente. Los cambios de estado son condicionales
 * ({@link #transition}): se aplican solo si el estado guardado sigue siendo el esperado, y nunca
 * vuelven a crear una fila borrada.
 */
public interface TeachingGuideImportRepositoryPort {

    Optional<TeachingGuideImport> findById(UUID id);

    Optional<TeachingGuideImport> findByIdAndUser(UUID id, UUID userId);

    TeachingGuideImport create(TeachingGuideImport guideImport);

    /**
     * Guarda {@code updated} solo si la fila existe y su estado sigue siendo {@code expected}.
     * Bloquea la fila hasta el final de la transacción, así que de dos peticiones a la vez solo
     * una gana.
     *
     * @return {@code true} si se guardó
     */
    boolean transition(TeachingGuideImport.Status expected, TeachingGuideImport updated);

    void delete(UUID id);
}
