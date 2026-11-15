package com.synaptixfit.domain.model.together;

/**
 * Situación de una persona en algo compartido con amigos (ADR 0044): invitada, dentro, ha dicho que no o ha salido.
 * Quien crea entra ya como {@code JOINED}.
 */
public enum MemberStatus {
    INVITED,
    JOINED,
    DECLINED,
    LEFT;

    /** Ve el detalle: está invitada o dentro (quien ha dicho que no o ha salido ya no lo ve). */
    public boolean canView() {
        return this == INVITED || this == JOINED;
    }
}
