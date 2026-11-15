package com.synaptixfit.domain.port.output.together;

import com.synaptixfit.domain.model.together.TogetherLiveChange;

/**
 * Canal en directo de «Con amigos» (ADR 0047). La implementación entrega el aviso solo si la transacción se confirma
 * (un cambio deshecho no se anuncia) y a quien tenga la app abierta; si no llega, el móvil lo verá en su próxima
 * lectura.
 */
public interface TogetherLivePort {

    void publish(TogetherLiveChange change);
}
