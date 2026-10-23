package com.synaptixfit.domain.model.privacy;

import java.util.UUID;

/**
 * Resultado de un borrado. {@code deletedRecords} cuenta las filas borradas directamente (las
 * dependientes en cascada no se cuentan); {@code failedFileDeletions} son los objetos de R2 que no
 * se pudieron borrar (el borrado de datos no se bloquea por ello).
 */
public record ErasureReport(UUID userId, ErasureMode mode, int deletedRecords, int storedFiles,
                            int failedFileDeletions) {
}
