package com.synaptixfit.domain.event.planner;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Un bloque de deporte sin rutina se ha marcado o desmarcado como hecho: Indicadores registra o retira su
 * carga física. {@code effort} es el esfuerzo percibido (1-10) o null si no se indicó.
 */
public record SportBlockCompletionChanged(UUID userId, UUID blockId, LocalDate date, Integer effort,
                                          int durationMinutes, boolean completed, Instant occurredAt)
        implements DomainEvent {
}
