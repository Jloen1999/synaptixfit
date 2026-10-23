package com.synaptixfit.domain.event.academic;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Se pidió analizar un plan docente. Es el único evento que se atiende fuera de la petición: el
 * oyente lo procesa en segundo plano cuando la transacción ya se ha confirmado, porque la IA
 * puede tardar más de un minuto y el móvil no debe esperar con la conexión abierta.
 */
public record TeachingGuideImportRequested(UUID userId, UUID importId, Instant occurredAt) implements DomainEvent {
}
