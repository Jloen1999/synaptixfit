package com.synaptixfit.domain.port.output.event;

import com.synaptixfit.domain.event.DomainEvent;

/** Publica eventos de dominio para los oyentes de otros módulos. */
public interface DomainEventPublisherPort {

    void publish(DomainEvent event);
}
