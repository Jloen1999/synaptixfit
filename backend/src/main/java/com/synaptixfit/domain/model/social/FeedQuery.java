package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.model.shared.PageRequest;
import java.time.Instant;
import java.util.UUID;

/**
 * Consulta del muro.
 *
 * @param authorId solo publicaciones de ese autor (opcional)
 * @param from     publicaciones creadas desde ese instante (opcional, filtro temporal)
 * @param since    solo publicaciones creadas después de ese instante (opcional, sondeo de novedades)
 */
public record FeedQuery(UUID viewerId, UUID authorId, Instant from, Instant since, PageRequest page) {
}
