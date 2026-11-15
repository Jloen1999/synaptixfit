package com.synaptixfit.infrastructure.adapter.output.event;

import com.synaptixfit.domain.model.together.TogetherLiveChange;
import com.synaptixfit.domain.port.output.together.TogetherLivePort;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link TogetherLivePort} (ADR 0047): deja el aviso en el bus de Spring y {@code TogetherLiveListener} lo
 * manda por SSE solo cuando la transacción se confirma. Así un cambio deshecho nunca se anuncia y el móvil, al volver
 * a leer, ya ve lo guardado.
 */
@Component
public class SpringTogetherLiveAdapter implements TogetherLivePort {

    private final ApplicationEventPublisher publisher;

    public SpringTogetherLiveAdapter(ApplicationEventPublisher publisher) {
        this.publisher = publisher;
    }

    @Override
    public void publish(TogetherLiveChange change) {
        publisher.publishEvent(change);
    }
}
