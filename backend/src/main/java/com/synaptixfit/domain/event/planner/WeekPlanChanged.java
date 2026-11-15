package com.synaptixfit.domain.event.planner;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * La semana que empieza el lunes {@code weekStart} ha quedado planificada (se dio la experiencia de planificar) o ha
 * dejado de estarlo (se borró su plan). Los retos que cuentan semanas planificadas se recuentan (ADR 0043).
 */
public record WeekPlanChanged(UUID userId, LocalDate weekStart, boolean planned, Instant occurredAt)
        implements DomainEvent {
}
