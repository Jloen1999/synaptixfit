package com.synaptixfit.domain.model.together;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.Set;
import java.util.UUID;

/**
 * Aviso en directo de «Con amigos» (ADR 0047): algo cambió en una sala, un entreno juntos o en lo de «Con amigos» de
 * estas personas. No lleva datos: cada móvil vuelve a leer por la API de siempre, con sus permisos de siempre.
 *
 * @param recipients quién debe enterarse (las personas de dentro o invitadas y quien actuó)
 * @param id         la sala o el entreno que cambió
 */
public record TogetherLiveChange(Set<UUID> recipients, Topic topic, UUID id) {

    /** Qué cambió: una sala de estudio, un entreno juntos o la lista de «Con amigos» (p. ej. una invitación). */
    public enum Topic { STUDY_ROOM, WORKOUT, TOGETHER }

    public TogetherLiveChange {
        recipients = Set.copyOf(Guard.notNull(recipients, "recipients"));
        Guard.notNull(topic, "topic");
        Guard.notNull(id, "id");
    }
}
