package com.synaptixfit.domain.port.output.insights;

import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import com.synaptixfit.domain.model.insights.PhysicalLoadRecord;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Registros de carga física ({@code registros_carga_fisica}). */
public interface PhysicalLoadRepositoryPort {

    Optional<PhysicalLoadRecord> findBySession(UUID userId, UUID sessionId);

    PhysicalLoadRecord save(PhysicalLoadRecord record);

    /** Borra el registro de la sesión. Devuelve si existía. */
    boolean deleteBySession(UUID userId, UUID sessionId);

    Optional<PhysicalLoadRecord> findByBlock(UUID userId, UUID blockId);

    /** Borra el registro del bloque de deporte. Devuelve si existía. */
    boolean deleteByBlock(UUID userId, UUID blockId);

    /**
     * Filas de carga entre dos fechas, ambas incluidas. Las sumas y agregados los calcula
     * {@link PhysicalLoadHistory} en el caso de uso.
     */
    List<PhysicalLoadHistory.Entry> entriesBetween(UUID userId, LocalDate from, LocalDate to);

    /** Todo el historial de carga del usuario (para el máximo diario). */
    List<PhysicalLoadHistory.Entry> allEntries(UUID userId);
}
