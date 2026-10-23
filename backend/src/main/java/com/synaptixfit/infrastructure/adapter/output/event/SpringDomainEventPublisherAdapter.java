package com.synaptixfit.infrastructure.adapter.output.event;

import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

/**
 * Publica eventos de dominio con el bus de eventos de Spring (síncrono, misma transacción).
 * Los oyentes viven en {@code infrastructure/adapter/input/event/<feature>/} y llaman a casos de uso.
 */
@Component
public class SpringDomainEventPublisherAdapter implements DomainEventPublisherPort {

    private final ApplicationEventPublisher publisher;

    public SpringDomainEventPublisherAdapter(ApplicationEventPublisher publisher) {
        this.publisher = publisher;
    }

    @Override
    public void publish(DomainEvent event) {
        publisher.publishEvent(event);
    }
}
