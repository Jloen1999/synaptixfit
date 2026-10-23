package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.PostType;
import java.util.UUID;

/**
 * Publicación automática de un logro (reto completado, insignia desbloqueada). Idempotente: si ya
 * existe una publicación del mismo tipo con los mismos {@code metadata} (la entidad del logro), no
 * se repite, para que descompletar y volver a completar un reto no duplique la publicación.
 */
public interface PublishAchievementPostUseCase {

    record Command(UUID userId, PostType type, String description, String metadata) {}

    /** @return true si se ha publicado; false si ya existía */
    boolean publishAchievement(Command command);
}
