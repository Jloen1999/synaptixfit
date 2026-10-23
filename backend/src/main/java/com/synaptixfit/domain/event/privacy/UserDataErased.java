package com.synaptixfit.domain.event.privacy;

import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.model.privacy.ErasureMode;
import java.time.Instant;
import java.util.UUID;

/**
 * Se han borrado los datos de un usuario (vaciado, anonimización o eliminación de la cuenta).
 * Los módulos con cachés o datos derivados fuera de la base de datos pueden reaccionar.
 */
public record UserDataErased(UUID userId, ErasureMode mode, Instant occurredAt) implements DomainEvent {
}
