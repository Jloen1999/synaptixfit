package com.synaptixfit.domain.model.social;

import java.util.UUID;

/** Datos públicos mínimos de un usuario para pintar contenido social. */
public record AuthorSummary(UUID id, String fullName, String avatarUrl) {
}
