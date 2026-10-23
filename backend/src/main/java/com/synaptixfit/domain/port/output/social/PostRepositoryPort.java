package com.synaptixfit.domain.port.output.social;

import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.PostType;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de publicaciones del muro. */
public interface PostRepositoryPort {

    Optional<Post> findById(UUID id);

    Post save(Post post);

    /** ¿Tiene el usuario una publicación de ese tipo con exactamente esos metadatos? */
    boolean existsByAuthorTypeAndMetadata(UUID userId, PostType type, String metadata);

    /** Borra la publicación con sus likes y comentarios (cascada). */
    void delete(UUID id);
}
