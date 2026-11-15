package com.synaptixfit.domain.model.together;

import java.util.UUID;

/** Lo único que se enseña de otra persona en lo compartido con amigos: nombre y foto. */
public record Person(UUID id, String name, String avatarUrl) {
}
