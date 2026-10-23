package com.synaptixfit.domain.event.training;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Se ha guardado el check-in diario (nuevo o actualizado). Gamificación evalúa insignias y racha;
 * si {@code requiresAdaptation}, Notificaciones avisa de la fatiga.
 */
public record CheckInSubmitted(UUID userId, LocalDate date, int fatigueScore, boolean requiresAdaptation,
                               Instant occurredAt) implements DomainEvent {
}
