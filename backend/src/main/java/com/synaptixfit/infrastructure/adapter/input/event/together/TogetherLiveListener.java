package com.synaptixfit.infrastructure.adapter.input.event.together;

import com.synaptixfit.domain.model.together.TogetherLiveChange;
import com.synaptixfit.infrastructure.adapter.input.rest.together.TogetherStreamHub;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Manda por el canal en directo ({@link TogetherStreamHub}) los avisos de «Con amigos» (ADR 0047) <em>después</em> del
 * commit: si la transacción se deshace, no se anuncia nada; y quien recibe el aviso, al volver a leer, ya ve el cambio.
 * Sin transacción no se manda (todos los casos de uso tienen una).
 */
@Component
public class TogetherLiveListener {

    private final TogetherStreamHub hub;

    public TogetherLiveListener(TogetherStreamHub hub) {
        this.hub = hub;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void on(TogetherLiveChange change) {
        hub.publish(change);
    }
}
